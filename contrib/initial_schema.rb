Sequel.migration do
  up do
   create_table :cando_users do
     String :id, :unique => true, :null => false, :primary_key => true
    end

   create_table :cando_roles do
     String :id, :unique => true, :null => false, :primary_key => true
   end

   create_table :cando_capabilities do
     String :id, :unique => true, :null => false, :primary_key => true
   end

   # associations
   create_table :cando_roles_users do
     String :user_id
     String :role_id
     primary_key [:user_id, :role_id], :name => :ur_pk
   end

   create_table :cando_capabilities_roles do
     String :role_id
     String :capability_id
     primary_key [:role_id, :capability_id], :name =>:rc_pk
   end
  end

  down do
    drop_table :cando_users
    drop_table :cando_roles
    drop_table :cando_capabilities
    drop_table :cando_roles_users
    drop_table :cando_capabilities_roles
  end
end
