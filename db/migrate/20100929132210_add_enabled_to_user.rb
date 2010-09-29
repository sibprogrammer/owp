class AddEnabledToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :enabled, :boolean, :default => true
  end

  def self.down
    remove_column :users, :enabled
  end
end
