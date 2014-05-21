require 'sequel' 

if File.basename($0) == "rake"    # we are in a rake call: export our rake stuff
  require 'rake'
  import File.join(File.dirname(File.dirname(__FILE__)), "lib", "tasks", "cando.rake" )
end

module CanDo
  class ConfigCannotBlockError < RuntimeError; end
  class ConfigMysqlDBError < RuntimeError; end
  class ConfigMysqlConnectionError < RuntimeError; end
  class DBNotConnected < RuntimeError; end

  def self.db
    @db or raise DBNotConnected.new("CanDo is not connected to a database")
  end

  def self.init(&block)
    CanDo.instance_eval &block

    begin
      Sequel::Model.db.test_connection
    rescue ::Sequel::Error => e
      raise DBNotConnected.new("No database connection established. Have you called 'connect' within the 'CanDo.init' block? Sequel error message is:\n#{e.message}")
    end

    Dir.glob(File.expand_path("#{__FILE__}/../models/*.rb")).each do |model|
      require_relative model
    end

    Sequel::Model.db
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

    @@cannot_block_proc = block
  end

  def self.connect(connection)
    if connection =~ /sqlite/
      raise ConfigMysqlDBError.new("sqlite is not supported as it misses certain constraints")
    end

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
      if @@cannot_block_proc
        self.instance_exec user_urn, capability, &@@cannot_block_proc
      end
    end

    has_permission
  end

  def define_role(role, capabilities)
    CanDo::Role.define_role(role, capabilities)
  end

  def assign_roles(user, roles)
    CanDo::User.find_or_create(:id => user).assign_roles(roles)
  end

  def roles(user)
    user = CanDo::User.first(:id => user)
    return [] unless user

    user.roles.map(&:id)
  end

  def capabilities(user)
    user = CanDo::User.first(:id => user)
    return [] unless user

    user.capabilities.map{|x| x.to_sym }
  end
end
