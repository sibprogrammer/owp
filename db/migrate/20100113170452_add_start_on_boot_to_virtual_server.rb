class AddStartOnBootToVirtualServer < ActiveRecord::Migration
  def self.up
    add_column :virtual_servers, :start_on_boot, :boolean, :default => true
  end

  def self.down
    remove_column :virtual_servers, :start_on_boot
  end
end
