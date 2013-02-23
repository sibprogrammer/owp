class ChangeIdentityTypeInVirtualServer < ActiveRecord::Migration
  def self.up
    change_column :virtual_servers, :identity, :string
  end

  def self.down
    change_column :virtual_servers, :identity, :integer
  end
end
