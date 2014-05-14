class Role < Sequel::Model
  many_to_many :users
  many_to_many :capabilities
  unrestrict_primary_key

  def before_destroy
    self.remove_all_capabilities
    self.remove_all_users
  end

  def self.setup_role(role, capabilities)
    r = Role.find_or_create(:id => role)
    r.remove_all_capabilities
    capabilities.each do |capability|
      r.add_capability( Capability.find_or_create(:id => capability) )
    end

    r
  end

  def to_s
    "#{id}\t#{capabilities.map(&:id).join(",")}"
  end
end
