require 'tmpdir'
require_relative '../db'

@cando_db_migration_dir = "db/cando-migrations"

namespace :cando do
  desc "Initialize cando (creates schema and runs migration)"
  task :init do
    if Dir.glob("#{@cando_db_migration_dir}/*_initial_schema.rb").empty?
      create_migration :create_schema do
        <<-EOF
Sequel.migration do
  up do
   create_table :users do
     String :id, :unique => true, :null => false
     primary_key :id
    end

   create_table :roles do
     String :id, :unique => true, :null => false
     primary_key :id
   end

   create_table :capabilities do
     String :id, :unique => true, :null => false
     primary_key :id
   end

   # associations
   create_table :roles_users do
     String :user_id
     String :role_id
     primary_key [:user_id, :role_id], :name => :ur_pk
   end

   create_table :capabilities_roles do
     String :role_id
     String :capability_id
     primary_key [:role_id, :capability_id], :name =>:rc_pk
   end
  end

  down do
    drop_table :users
    drop_table :roles
    drop_table :capabilities
    drop_table :roles_users
    drop_table :capabilities_roles
  end
end
        EOF
      end
    else
      $stderr.puts red("skipping first migration file: already exists")
    end

    Rake::Task['cando:migrate'].invoke

    puts <<EOF
    #{green("Success!")}

In order to add, update or remove a role, call

    rake cando:add    role=<rolename> capabilities=<cap1>,<cap2>,<cap3>
    rake cando:update role=<rolename> capabilities=<cap1>,<cap2>,<cap3>
    rake cando:remove role=<rolename>

When adding or updating a roles it doesn't matter whether the passed in capabilities
exist or not -- if not existant, they will be created automatically


EOF

  end

  desc "Migrate cando db"
  task :migrate, [:version] do |_, args|
    Sequel.extension :migration

    if version = args[:version]
      puts "Migrating to version #{version}"
      Sequel::Migrator.run(Cando.connect, @cando_db_migration_dir, { allow_missing_migration_files: true, target: version.to_i } )
    else
      puts "Migrating to latest"
      Sequel::Migrator.run(Cando.connect, @cando_db_migration_dir, { allow_missing_migration_files: true} )
    end
  end

  desc "Add a new role (pass in role name and capabilities with role=<name> capabilities=<cap1>,<cap2>,... )"
  task :add do
    setup_role(false)
  end

  desc "Update role (pass in role name and capabilities with role=<name> capabilities=<cap1>,<cap2>,... )"
  task :update do
    setup_role(true)
  end


  desc "Remove role (pass in role name with role=<name>)"
  task :remove do
    unless ENV['role']
      $stderr.puts red("usage: rake cando:remove role=<rolename>")
      exit 1
    end

    unless r = Role.find(:id => ENV['role'])
      $stderr.puts red("role '#{args.role}' does not exist")
      exit 1
    end

    r.destroy
  end

  desc "Assign role to user (args: roles=<r1>,<r2>,<rn> user=<user_urn>)"
  task :assign do
    roles = ENV['roles']
    user_urn  = ENV['user']

    unless roles && user_urn
      $stderr.puts red("usage: rake cando:assign user=<user_urn> roles=<role1>,<role2>,... ")
    end


    roles.split(",").each do |role_name|
      role = Role.find(:id => role_name)
      unless role
        $stderr.puts red("Role '#{role_name}' does not exist")
        exit 1
      end

      begin
        role.add_user( User.find_or_create(:id => user_urn) )
      rescue Sequel::UniqueConstraintViolation => e
        $stderr.puts "user already has role '#{role_name}'"
      end
    end
  end

  desc "List roles"
  task :list do
    puts "ROLE\tCAPABILITIES"
    Role.all.each do |role|
      puts role
    end
  end

  desc "List users and their roles"
  task :users do
    puts "USER_URN\tROLES"
    User.all.each do |user|
      puts user
    end
  end

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

def setup_role(force = false)
  role         = ENV['role']
  capabilities = ENV['capabilities'] && ENV['capabilities'].split(",")

  unless role && capabilities
    puts red("usage: rake cando:add    role=<rolename> capabilities=<cap1>,<cap2>,<cap3>")
    exit 1
  end

  if !force && Role.find(:id => role)
    puts red("Role '#{role}' already exists!")
    puts "If you want to update '#{role}', please use 'rake cando:update'"
    exit 1
  end

  Role.setup_role(role, capabilities)
end
