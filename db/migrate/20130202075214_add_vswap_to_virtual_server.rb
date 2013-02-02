class AddVswapToVirtualServer < ActiveRecord::Migration
  def self.up
    add_column :virtual_servers, :vswap, :integer, :default => 0
  end

  def self.down
    remove_column :virtual_servers, :vswap
  end
end
