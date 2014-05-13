require 'tmpdir'
namespace :cando do
  db_dir = "db"
  cando_db_config = "#{db_dir}/cando-config.yml"
  cando_db_migration_dir = "#{db_dir}/cando-migrate"
  cando_schema = "#{db_dir}/cando-schema.rb"
  cando_migrations_config = ".cando.standalone_migrations"

  desc "Initialize cando (creates db and runs migrations)"
  task :init do
    puts "Creating cando db configuration files:"

    create_file cando_migrations_config do
      <<-EOF
db:
    seeds: db/cando-seeds.rb
    migrate: #{cando_db_migration_dir}
    schema: #{cando_schema}
config:
    database: #{cando_db_config}

      EOF
    end

    create_file "db/cando-migrate/README.txt" do
"put cando migration files here"
    end

    if Dir.glob("#{cando_db_migration_dir}/*_create_capabilities.rb").empty?
      create_file "#{cando_db_migration_dir}/#{Time.now.strftime("%Y%m%d%H%M%S")}_create_capabilities.rb" do
        <<-EOF
  class CreateCapabilities < ActiveRecord::Migration
    def up
     create_table :capabilities do |t|
        t.string  :user_id
        t.binary  :base
      end

      add_index :capabilities, :user_id
    end

    def down
      drop_table :capabilities
    end
  end
        EOF
      end
    else
      puts red("skipping first migration file: already exists")
    end

    puts <<-EOF

Basic structure created:
- store your cando-db config in: #{cando_db_config}
- put your migrations in #{cando_db_migration_dir}
- the cando schema will be dumped to #{cando_schema}

EOF

    unless File.exist? cando_db_config
      puts red("please create db config in #{cando_db_config} and run again")
      exit 1
    end

    cando_migrations do
      Rake::Task['db:create'].invoke
    end

    puts green("success -- now run 'rake cando:migrate'")
  end

  desc "Migrate cando db"
  task :migrate do
    cando_migrations do
      Rake::Task['db:migrate'].invoke(ENV['VERSION'])
    end
  end

  desc "Add a new capability (pass in capability name with CAPABILITY=<name>)"
  task :add do

  end

  desc "Remove capability (pass in capability name with CAPABILITY=<name>)"
  task :remove do

  end

  desc "List capabilities"
  task :list do

  end


  desc "Destroy cando (drops db)"
  task :destroy do
    cando_migrations do
      begin
        debugger
        Rake::Task['db:drop'].invoke
        puts green("dropped db")
      rescue
        puts red("dropping db failed -- continuing anyways")
      end
    end

    mvtmp cando_db_config
    mvtmp cando_schema
    mvtmp cando_db_migration_dir
    mvtmp cando_migrations_config
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

def cando_migrations
  db_env = ENV['DATABASE']
  ENV['DATABASE'] = "cando"

  require 'standalone_migrations'
  StandaloneMigrations::Tasks.load_tasks
  yield
  ENV['DATABASE'] = db_env
end

def green(text)
  "\033[1;32;48m#{text}\033[m"
end

def red(text)
  "\033[1;31;48m#{text}\033[m"
end
