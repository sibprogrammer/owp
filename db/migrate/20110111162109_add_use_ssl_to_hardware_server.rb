class AddUseSslToHardwareServer < ActiveRecord::Migration
  def self.up
    add_column :hardware_servers, :use_ssl, :boolean, :default => false
  end

  def self.down
    remove_column :hardware_servers, :use_ssl
  end
end
