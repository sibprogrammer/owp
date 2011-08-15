class CreatePermissionsRoles < ActiveRecord::Migration
  def self.up
    create_table :permissions_roles, :id => false do |t|
      t.integer :permission_id
      t.integer :role_id
    end

    superadmin_role = Role.find_by_name('superadmin')
    superadmin_role.permissions = Permission.all

    ve_admin_role = Role.find_by_name('ve_admin')
    %w( use_ve_console backup_ve reinstall_ve create_requests ).each do |perm_name|
      ve_admin_role.permissions << Permission.find_by_name(perm_name)
    end
  end

  def self.down
    drop_table :permissions_roles
  end
end
