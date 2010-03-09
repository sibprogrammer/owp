class AddOrigServerTemplateToVirtualServer < ActiveRecord::Migration
  def self.up
    add_column :virtual_servers, :orig_server_template, :string
  end

  def self.down
    remove_column :virtual_servers, :orig_server_template
  end
end
