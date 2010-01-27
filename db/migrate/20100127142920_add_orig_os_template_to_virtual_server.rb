class AddOrigOsTemplateToVirtualServer < ActiveRecord::Migration
  def self.up
    add_column :virtual_servers, :orig_os_template, :string
  end

  def self.down
    remove_column :virtual_servers, :orig_os_template
  end
end
