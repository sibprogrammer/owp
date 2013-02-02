class AddVswapToHardwareServer < ActiveRecord::Migration
  def self.up
    add_column :hardware_servers, :vswap, :boolean, :default => false
  end

  def self.down
    remove_column :hardware_servers, :vswap
  end
end
