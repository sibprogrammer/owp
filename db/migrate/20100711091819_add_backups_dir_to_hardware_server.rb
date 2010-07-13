class AddBackupsDirToHardwareServer < ActiveRecord::Migration
  def self.up
    add_column :hardware_servers, :backups_dir, :string
  end

  def self.down
    remove_column :hardware_servers, :backups_dir
  end
end
