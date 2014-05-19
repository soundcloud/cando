module CanDo
  class UndefinedRole < Exception; end
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
        roles.each do |r|
          begin
            role = r.is_a?(CanDo::Role) ? r : CanDo::Role.where(:id => r).first!
            self.add_role(role)
          rescue Sequel::UniqueConstraintViolation => e
            puts "user already has role '#{r}'"
          rescue Sequel::NoMatchingRow
            raise UndefinedRole.new("Role '#{r}' does not exist")
          end
        end
      end
      self
    end

    def role_names
      roles.map(&:id)
    end

    def to_s
      "#{id}\t#{role_names.join(",")}\t#{capabilities.join(",")}"
    end
  end
end
