require 'sequel'

module Cando
  def self.connect
    return @db if @db

    unless ENV['CANDO_DB']
      puts <<-EOF
In order to use cando you need to pass in the db configuration via the env variable $CANDO_DB, e.g.

  CANDO_DB=mysql://user:passwd@host/database <your command>
      EOF
      exit 1
    end

    begin
      @db = Sequel.connect(ENV['CANDO_DB'])
      @db.test_connection
      return @db
    rescue => e
      puts <<-EOF
Error connecting to '#{ENV['CANDO_DB']}': #{e.message}

Are you sure your dbms is running, the db exists and user/password are correct?
If you need to create the db and user/passwd, connect to your db as root and
execute the following (adjust values as fit):

    CREATE DATABASE IF NOT EXISTS cando  DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;
    GRANT ALL ON `cando`.* to 'cando_user'@'localhost' identified by 'cando_passwd';

EOF
exit 1
    end
  end
end

Cando.connect
Dir.glob(File.expand_path("#{__FILE__}/../models/*.rb")).each do |model|
  require_relative model
end

