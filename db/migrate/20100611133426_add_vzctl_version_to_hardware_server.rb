class AddVzctlVersionToHardwareServer < ActiveRecord::Migration
  def self.up
    add_column :hardware_servers, :vzctl_version, :string
  end

  def self.down
    remove_column :hardware_servers, :vzctl_version
  end
end
