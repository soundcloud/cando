module CanDo
  class Capability < Sequel::Model(:cando_capabilities)
    many_to_many :roles, :join_table => :cando_capabilities_roles
    unrestrict_primary_key
  end
end
