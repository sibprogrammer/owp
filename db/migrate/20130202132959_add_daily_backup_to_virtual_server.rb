class AddDailyBackupToVirtualServer < ActiveRecord::Migration
  def self.up
    add_column :virtual_servers, :daily_backup, :boolean, :default => false
  end

  def self.down
    remove_column :virtual_servers, :daily_backup
  end
end
