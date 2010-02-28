class AddTemplatesDirToHardwareServer < ActiveRecord::Migration
  def self.up
    add_column :hardware_servers, :templates_dir, :string
  end

  def self.down
    remove_column :hardware_servers, :templates_dir
  end
end
