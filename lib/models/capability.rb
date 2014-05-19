module CanDo
  class Capability < Sequel::Model(:cando_capabilities)
    many_to_many :roles, :join_table => :cando_capabilities_roles
    unrestrict_primary_key
    
    def self.cleanup
      Capability.all do |cap|
        if cap.roles.count == 0
          cap.destroy
        end
      end
    end
  end
end
