class AddOsSelectionOnReinstallPermission < ActiveRecord::Migration
  def self.up
    Permission.create({ :name => 'select_os_on_reinstall' })

    superadmin_role = Role.find_by_name('superadmin')
    superadmin_role.permissions << Permission.find_by_name('select_os_on_reinstall')

    ve_admin_role = Role.find_by_name('ve_admin')
    ve_admin_role.permissions << Permission.find_by_name('select_os_on_reinstall')
  end

  def self.down
    Permission.find_by_name('select_os_on_reinstall').delete
  end
end
