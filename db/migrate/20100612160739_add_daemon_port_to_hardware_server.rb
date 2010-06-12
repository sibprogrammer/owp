class AddDaemonPortToHardwareServer < ActiveRecord::Migration
  def self.up
    add_column :hardware_servers, :daemon_port, :integer, :default => 7767
  end

  def self.down
    remove_column :hardware_servers, :daemon_port
  end
end
