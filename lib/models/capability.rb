class Capability < Sequel::Model
  many_to_many :roles
  unrestrict_primary_key
end
