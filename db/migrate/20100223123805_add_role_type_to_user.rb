class AddRoleTypeToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :role_type, :integer, :default => 1
  end

  def self.down
    remove_column :users, :role_type
  end
end
