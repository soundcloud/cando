require 'tmpdir'
require_relative '../db'
include Cando

@cando_db_migration_dir = "db/cando-migrations"

namespace :cando do
  desc "Initialize cando (creates db and runs migrations)"
  task :init do
    if Dir.glob("#{@cando_db_migration_dir}/*_create_roles.rb").empty?
      create_migration :create_roles do
        <<-EOF
Sequel.migration do
  up do
   create_table :roles do
     String :user_urn, :unique => true, :null => false
     primary_key :user_urn
    end
  end

  down do
    drop_table :roles
  end
end
        EOF
      end
    else
      puts red("skipping first migration file: already exists")
    end

    Rake::Task['cando:migrate'].invoke

    puts <<EOF
#{green("Success!")}

In order to add or remove a role, call

    rake cando:add[<role_name>]
    rake cando:rm[<role_name>]

respectively. If the default value of a new role should be granted by default, call

    rake cando:add[<role_name>,true]

EOF

  end

  desc "Migrate cando db"
  task :migrate, [:version] do |_, args|
    Sequel.extension :migration

    if version = args[:version]
      puts "Migrating to version #{version}"
      Sequel::Migrator.run(db, @cando_db_migration_dir, { allow_missing_migration_files: true, target: version.to_i } )
    else
      puts "Migrating to latest"
      Sequel::Migrator.run(db, @cando_db_migration_dir, { allow_missing_migration_files: true} )
    end
  end

  desc "Add a new role (pass in role name with ROLE=<name>)"
  task :add, :role, :grant_by_default do |_, args|
    unless args.role
      puts red("usage: rake cando:add[<role_name>] / rake cando:add[<role_name>,true] # grant this role by default")
      exit 1
    end

    grant_by_default = ( args.grant_by_default == "true" )

    create_migration "add_#{args.role}_role" do
      <<-EOF
Sequel.migration do
  up do
    alter_table :roles do
      add_column :#{args.role}, TrueClass, :null => false, :default => #{grant_by_default}
    end
  end

  down do
    alter_table :roles do
      drop_column :#{args.role}
    end
  end
end
      EOF
    end
  end

  desc "Remove role (pass in role name with ROLE=<name>)"
  task :remove, :role do |_, args|
    unless args.role
      puts red("usage: rake cando:remove[<role_name>]")
      exit 1
    end

    unless roles.keys.include?(args.role.to_sym)
      puts red("role '#{args.role}' does not exist")
      exit 1
    end

    create_migration "remove_#{args.role}_role" do
      <<-EOF
Sequel.migration do
  up do
    alter_table :roles do
      drop_column :#{args.role}
    end
  end

  down do
    alter_table :roles do
      add_column :#{args.role}, TrueClass, :null => false, :default => #{roles[args.role.to_sym]}
    end
  end
end

EOF

    end
  end

  desc "List roles"
  task :list do
    roles.each do |name, grant_by_default|
      if grant_by_default
        puts "#{name}\t(granted by default)"
      else
        puts "#{name}"
      end
    end
  end
end

def mvtmp(file_name)
  @@tmp_dir ||= Dir.mktmpdir
  unless File.exists? file_name
    puts red("skipping #{file_name}: does not exist")
    return
  end

  puts green("moving #{file_name} to #{@@tmp_dir}")
  FileUtils.mv file_name, @@tmp_dir
end

def create_migration(name)
  migration_path = "#{@cando_db_migration_dir}/#{Time.now.strftime("%Y%m%d%H%M%S")}_#{name}.rb"
  create_file migration_path do
    yield
  end

  puts "run 'rake cando:migrate' to execute migration"
end

def create_file(file_name)
  if File.exists? file_name
    puts red("skipping #{file_name}: already exists")
    return
  end

  puts green("creating #{file_name}")
  unless File.exists? File.dirname(file_name)
    FileUtils.mkdir_p File.dirname(file_name)
  end


  if block_given?
    File.open(file_name, 'w') do |f|
      f << yield
    end
  else
    FileUtils.touch file_name
  end
end

def green(text)
  "\033[1;32;48m#{text}\033[m"
end

def red(text)
  "\033[1;31;48m#{text}\033[m"
end
