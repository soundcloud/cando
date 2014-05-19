module CanDo
  class Role < Sequel::Model(:cando_roles)
    many_to_many :users, :join_table => :cando_roles_users
    many_to_many :capabilities, :join_table => :cando_capabilities_roles
    unrestrict_primary_key

    def before_destroy
      self.remove_all_capabilities
      self.remove_all_users
      Capability.cleanup
    end

    def self.define_role(name, capabilities)
      role = Role.find_or_create(:id => name)
      role.remove_all_capabilities
      capabilities.each do |capability|
        role.add_capability( Capability.find_or_create(:id => capability.to_s) )
      end

      role
    end

    def to_s
      "#{id}\t#{capabilities.map(&:id).join(",")}"
    end
  end
end
