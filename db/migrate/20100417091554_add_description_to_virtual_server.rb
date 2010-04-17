class AddDescriptionToVirtualServer < ActiveRecord::Migration
  def self.up
    add_column :virtual_servers, :description, :string
  end

  def self.down
    remove_column :virtual_servers, :description
  end
end
