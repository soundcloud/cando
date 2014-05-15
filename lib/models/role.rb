module CanDo
  class Role < Sequel::Model(:cando_roles)
    many_to_many :users, :join_table => :cando_roles_users
    many_to_many :capabilities, :join_table => :cando_capabilities_roles
    unrestrict_primary_key

    def before_destroy
      self.remove_all_capabilities
      self.remove_all_users
    end

    def self.setup_role(role, capabilities)
      role = Role.find_or_create(:id => role)
      role.remove_all_capabilities
      capabilities.each do |capability|
        role.add_capability( Capability.find_or_create(:id => capability) )
      end

      role
    end

    def to_s
      "#{id}\t#{capabilities.map(&:id).join(",")}"
    end
  end
end
