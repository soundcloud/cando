if File.basename($0) == "rake"    # we are in a rake call: export our rake stuff
  require 'rake'
  gem_root = File.dirname(File.dirname(File.absolute_path(__FILE__)))
  import "#{gem_root}/lib/tasks/cando.rake"
else
  require_relative './db'
end

module CanDo
  def can(user_urn, capability)
    can_do = User.find_or_create(:id => user_urn).can(capability)
    if can_do
      return yield if block_given?
    end

    can_do
  end
end
