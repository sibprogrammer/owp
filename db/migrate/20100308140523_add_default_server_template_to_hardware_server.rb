class AddDefaultServerTemplateToHardwareServer < ActiveRecord::Migration
  def self.up
    add_column :hardware_servers, :default_server_template, :string
  end

  def self.down
    remove_column :hardware_servers, :default_server_template
  end
end
