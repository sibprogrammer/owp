class AddNameserverToVirtualServer < ActiveRecord::Migration
  def self.up
    add_column :virtual_servers, :nameserver, :string
  end

  def self.down
    remove_column :virtual_servers, :nameserver
  end
end
