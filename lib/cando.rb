require 'Sequel' 

if File.basename($0) == "rake"    # we are in a rake call: export our rake stuff
  require 'rake'
  import File.join(File.dirname(File.dirname(__FILE__)), "lib", "tasks", "cando.rake" )
end

module CanDo
  class ConfigCannotBlockError < RuntimeError; end
  class ConfigMysqlConnectionError < RuntimeError; end
  class DBNotConnected < RuntimeError; end

  def db
    @db or raise DBNotConnected.new("CanDo is not connected to a database")
  end

  def self.init(&block)
    CanDo.instance_eval &block

    Dir.glob(File.expand_path("#{__FILE__}/../models/*.rb")).each do |model|
      require_relative model
    end
  end

  # will be executed if `can(user_urn, :capability) { }` will not be executed
  # due to missing capabilities
  def self.cannot_block(&block)
    if !block
      raise ConfigCannotBlockError.new("CanDo#cannot_block expects block")
    end
    if block.arity != 2
      raise ConfigCannotBlockError.new("CanDo#cannot_block expects block expecting two arguments |user_urn, capability|")
    end

    @cannot_block_proc = block
  end
  def cannot_block_proc
    @cannot_block_proc
  end


  def self.connect(connection)
    begin
      @db = Sequel.connect(connection)
      @db.test_connection
      @db
    rescue => e
      raise ConfigMysqlConnectionError.new(<<-EOF
Error connecting to database. Be sure to pass in a databse config like 'mysql://user:passwd@host/database':
#{e.message}
EOF
      )
    end
  end

  def can(user_urn, capability)
    user = CanDo::User.find(:id => user_urn)
    has_permission = user && user.can(capability)

    if block_given?
      if has_permission
       return yield
      end
      if CanDo.cannot_block_proc
        CanDo.cannot_block_proc.call(user_urn, capability)
      end
    end

  end

  def define_role(role, capabilities)
    CanDo::Role.define_role(role, capabilities)
  end

  def assign_roles(user, roles)
    CanDo::User.find_or_create(:id => user).assign_roles(roles)
  end
end
