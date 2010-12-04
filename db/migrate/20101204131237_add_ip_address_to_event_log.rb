class AddIpAddressToEventLog < ActiveRecord::Migration
  def self.up
    add_column :event_logs, :ip_address, :string
  end

  def self.down
    remove_column :event_logs, :ip_address
  end
end
