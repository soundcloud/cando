require 'simplecov'
require 'cando'

module SimpleCov::Configuration
  def clean_filters
    @filters = []
  end
end

SimpleCov.configure do
  clean_filters
  load_profile 'test_frameworks'
end

ENV["COVERAGE"] && SimpleCov.start do
  add_filter "/.rvm/"
end
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rspec'
require 'cando'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

ENV['CANDO_TEST_DB'] ||= 'mysql://cando_user:cando_passwd@localhost/cando'

RSpec.configure do |config|
  Sequel.extension :migration
  migration = eval(File.read(File.join(File.dirname(File.dirname(__FILE__)), "contrib", "initial_schema.rb")))
  db = nil

  config.before(:suite) do
    db = CanDo.init do
      db = connect ENV['CANDO_TEST_DB']
      db.drop_table(*db.tables)
      migration.apply(db, :up)
    end
  end

  config.before(:each) do
    db.drop_table(*db.tables)
    migration.apply(db, :up)
  end
end

def connect
end
