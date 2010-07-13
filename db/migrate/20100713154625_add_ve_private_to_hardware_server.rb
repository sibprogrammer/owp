class AddVePrivateToHardwareServer < ActiveRecord::Migration
  def self.up
    add_column :hardware_servers, :ve_private, :string
  end

  def self.down
    remove_column :hardware_servers, :ve_private
  end
end
