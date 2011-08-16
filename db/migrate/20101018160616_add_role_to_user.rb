class AddRoleToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :role_id, :integer

    superadmin_role = Role.find_by_name('superadmin')
    ve_admin_role = Role.find_by_name('ve_admin')

    User.after_update.clear
    User.reset_column_information
    User.find(:all).each do |user|
      user.update_attribute :role_id, user.role_type == 1 ? superadmin_role.id : ve_admin_role.id
    end

    remove_column :users, :role_type
  end

  def self.down
    add_column :users, :role_type, :integer, :default => 1
    remove_column :users, :role_id
  end
end
