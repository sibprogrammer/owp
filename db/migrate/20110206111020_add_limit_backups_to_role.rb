class AddLimitBackupsToRole < ActiveRecord::Migration
  def self.up
    add_column :roles, :limit_backups, :integer, :default => -1

    Role.reset_column_information
    ve_admin_role = Role.find_by_name('ve_admin')
    ve_admin_role.limit_backups = 3
    ve_admin_role.save
  end

  def self.down
    remove_column :roles, :limit_backups
  end
end
