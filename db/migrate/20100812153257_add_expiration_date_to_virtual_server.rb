class AddExpirationDateToVirtualServer < ActiveRecord::Migration
  def self.up
    add_column :virtual_servers, :expiration_date, :date
  end

  def self.down
    remove_column :virtual_servers, :expiration_date
  end
end
