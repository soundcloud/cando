class User < Sequel::Model
  many_to_many :roles
  unrestrict_primary_key

  def capabilities
    roles.inject([]){|a,role| a << role.capabilities}.flatten.uniq.map(&:id)
  end

  def can(capability)
    capabilities.include?(capability.to_s)
  end

  def to_s
    "#{id}\t#{roles.map(&:id).join(",")}"
  end
end
