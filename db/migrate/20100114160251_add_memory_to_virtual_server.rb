class AddMemoryToVirtualServer < ActiveRecord::Migration
  def self.up
    add_column :virtual_servers, :memory, :integer, :default => 256
  end

  def self.down
    remove_column :virtual_servers, :memory
  end
end
