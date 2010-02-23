class AddUserIdToVirtualServer < ActiveRecord::Migration
  def self.up
    add_column :virtual_servers, :user_id, :integer, :default => 0
  end

  def self.down
    remove_column :virtual_servers, :user_id
  end
end
