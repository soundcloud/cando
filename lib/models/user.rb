module CanDo
  class User < Sequel::Model(:cando_users)
    many_to_many :roles, :join_table => :cando_roles_users
    unrestrict_primary_key

    def capabilities
      roles.inject([]){|a,role| a << role.capabilities}.flatten.uniq.map(&:id)
    end

    def can(capability)
      capabilities.include?(capability.to_s)
    end

    def assign_roles(roles)
      self.class.db.transaction do
        self.remove_all_roles
        roles.each do |role_name|
          begin
            role = CanDo::Role.where(:id => role_name).first!
            self.add_role(role)
          rescue Sequel::UniqueConstraintViolation => e
            puts "user already has role '#{role_name}'"
          rescue Sequel::NoMatchingRow
            raise "Role '#{role_name}' does not exist"
          end
        end
      end
    end

    def to_s
      "#{id}\t#{roles.map(&:id).join(",")}"
    end
  end
end
