require 'sequel' 

if File.basename($0) == "rake"    # we are in a rake call: export our rake stuff
  require 'rake'
  import File.join(File.dirname(File.dirname(__FILE__)), "lib", "tasks", "cando.rake" )
end

module CanDo
  # The provided cannot_block is not as expected
  class ConfigCannotBlockError < RuntimeError; end

  # CanDo.connect received an invalid or unsupported connection string
  class ConfigDBError < RuntimeError; end

  # Error while trying to connect to the database
  class ConfigConnectionError < RuntimeError; end

  # CanDo is not connected to a database but connection is needed
  class DBNotConnected < RuntimeError; end

  # Return current database connection
  #
  # raises DBNotConnected exception if CanDo is not connected to a db
  def self.db
    @db or raise DBNotConnected.new("CanDo is not connected to a database")
  end

  # Initializes CanDo
  #
  # This method should be called during boot up to configure CanDo with the db
  # connection and the cannot_block:
  #
  #    CanDo.init do
  #      # this will be executed if the user does not have the
  #      # asked-for capability (only applies if 'can' is passed a block)
  #      cannot_block do |user_urn, capability|
  #        raise "#{user_urn} can not #{capability} .. user capabilities are: #{capabilities(user_urn)}"
  #      end
  #
  #      connect "mysql://cando_user:cando_passwd@host:port/database"
  #    end
  #
  # ...
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


  # Block to be executed if <tt>can("user", :cap) { }</tt> will not be executed due to missing capability
  #
  # - the block needs to accept two arguments <tt>|user_urn, capability|</tt>
  # - this function should be called in the init method (see there for an example).
  # - if this block gets executed, it'll have the context of the <tt>can(...){ }</tt> call
  def self.cannot_block(&block)
    if !block
      raise ConfigCannotBlockError.new("CanDo#cannot_block expects block")
    end
    if block.arity != 2
      raise ConfigCannotBlockError.new("CanDo#cannot_block expects block expecting two arguments |user_urn, capability|")
    end

    @@cannot_block_proc = block
  end

  # Connect to database
  #
  # Pass in a connection string of the form
  #
  #     mysql://user:passwd@host:port/database
  #
  # Raises CanDo::ConfigConnectionError or CanDo::ConfigDBError when problems occur
  def self.connect(connection)
    if connection =~ /sqlite/
      raise ConfigDBError.new("sqlite is not supported as it misses certain constraints")
    end

    begin
      @db = Sequel.connect(connection)
      @db.test_connection
      @db
    rescue => e
      raise ConfigConnectionError.new(<<-EOF
Error connecting to database. Be sure to pass in a databse config like 'mysql://user:passwd@host/database':
#{e.message}
EOF
      )
    end
  end

  # Method to check whether a user has a certain capability
  #
  # It can be used in two manners:
  #
  # * pass it a block which is only executed if the user has the capability:
  #
  #     can("user_urn", :capability) do
  #       puts "woohoo"
  #     end
  #
  # this will execute cannot_block if user is missing this capability.
  #
  # * use as an expression that return true or false/nil
  #
  #    if can("user_urn", :capability) do
  #       puts "woohoo"
  #    else
  #       puts "epic fail"
  #    end
  #
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

  # Define or redefine a role
  #
  # Capabilities will be created if they don't exist yet
  def define_role(role, capabilities)
    CanDo::Role.define_role(role, capabilities)
  end

  # Assign role(s) to a user
  #
  #     assign_roles("user_urn", ["role_name", role_object])
  #
  # - if no user with that id exist, a new one will be created
  # - if a role does not exist, an CanDo::Role::UndefinedRole is raised
  # - you can pass in a role object or just role names (see example above)
  # - pass in an empty array to remove all roles from user
  def assign_roles(user, roles)
    CanDo::User.find_or_create(:id => user).assign_roles(roles)
  end

  # Get user's roles
  #
  # returns an array of strings
  def roles(user)
    user = CanDo::User.first(:id => user)
    return [] unless user

    user.roles.map(&:id)
  end

  # Get user's capabilities
  #
  # returns an array of strings
  def capabilities(user)
    user = CanDo::User.first(:id => user)
    return [] unless user

    user.capabilities.map{|x| x.to_sym }
  end
end
