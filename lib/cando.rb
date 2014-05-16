if File.basename($0) == "rake"    # we are in a rake call: export our rake stuff
  require 'rake'
  import File.join(File.dirname(File.dirname(__FILE__)), "lib", "tasks", "cando.rake" )
else
  require_relative './db'
end

module CanDoHelper
  def can(user_urn, capability)
    user = CanDo::User.find(:id => user_urn)
    has_permission = user && user.can(capability)

    if block_given? && has_permission
       return yield
    end

    has_permission
  end
end
