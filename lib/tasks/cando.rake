require 'tmpdir'
require_relative '../db'
include Cando

@cando_db_migration_dir = "db/cando-migrations"

namespace :cando do
  desc "Initialize cando (creates db and runs migrations)"
  task :init do
    if Dir.glob("#{@cando_db_migration_dir}/*_create_capabilities.rb").empty?
      create_migration :create_capabilities do
        <<-EOF
Sequel.migration do
  up do
   create_table :capabilities do
     String :user_urn, :unique => true, :null => false
     primary_key :user_urn
    end
  end

  down do
    drop_table :capabilities
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

In order to add or remove a capability, call

    rake cando:add[<capability_name>]
    rake cando:rm[<capability_name>]

respectively. If the default value of a new capability should be granted by default, call

    rake cando:add[<capability_name>,true]

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

  desc "Add a new capability (pass in capability name with CAPABILITY=<name>)"
  task :add, :capability, :grant_by_default do |_, args|
    unless args.capability
      puts red("usage: rake cando:add[<capability_name>] / rake cando:add[<capability_name>,true] # grant this capability by default")
      exit 1
    end

    grant_by_default = ( args.grant_by_default == "true" )

    create_migration "add_#{args.capability}_capability" do
      <<-EOF
Sequel.migration do
  up do
    alter_table :capabilities do
      add_column :#{args.capability}, TrueClass, :null => false, :default => #{grant_by_default}
    end
  end

  down do
    alter_table :capabilities do
      drop_column :#{args.capability}
    end
  end
end
      EOF
    end
  end

  desc "Remove capability (pass in capability name with CAPABILITY=<name>)"
  task :remove, :capability do |_, args|
    unless args.capability
      puts red("usage: rake cando:remove[<capability_name>]")
      exit 1
    end

    unless capabilities.keys.include?(args.capability.to_sym)
      puts red("capability '#{args.capability}' does not exist")
      exit 1
    end

    create_migration "remove_#{args.capability}_capability" do
      <<-EOF
Sequel.migration do
  up do
    alter_table :capabilities do
      drop_column :#{args.capability}
    end
  end

  down do
    alter_table :capabilities do
      add_column :#{args.capability}, TrueClass, :null => false, :default => #{capabilities[args.capability.to_sym]}
    end
  end
end

EOF

    end
  end

  desc "List capabilities"
  task :list do
    capabilities.each do |name, grant_by_default|
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
