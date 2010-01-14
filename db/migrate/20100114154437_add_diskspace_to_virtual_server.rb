class AddDiskspaceToVirtualServer < ActiveRecord::Migration
  def self.up
    add_column :virtual_servers, :diskspace, :integer, :default => 1024
  end

  def self.down
    remove_column :virtual_servers, :diskspace
  end
end
