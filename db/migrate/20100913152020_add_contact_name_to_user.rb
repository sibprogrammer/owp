class AddContactNameToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :contact_name, :string
  end

  def self.down
    remove_column :users, :contact_name
  end
end
