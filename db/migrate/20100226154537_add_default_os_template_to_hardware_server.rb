class AddDefaultOsTemplateToHardwareServer < ActiveRecord::Migration
  def self.up
    add_column :hardware_servers, :default_os_template, :string
  end

  def self.down
    remove_column :hardware_servers, :default_os_template
  end
end
