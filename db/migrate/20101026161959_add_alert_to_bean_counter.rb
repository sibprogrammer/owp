class AddAlertToBeanCounter < ActiveRecord::Migration
  def self.up
    add_column :bean_counters, :alert, :boolean, :default => false
  end

  def self.down
    remove_column :bean_counters, :alert
  end
end
