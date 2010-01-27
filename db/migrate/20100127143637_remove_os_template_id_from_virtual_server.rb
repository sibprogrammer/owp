class RemoveOsTemplateIdFromVirtualServer < ActiveRecord::Migration
  def self.up
    remove_column :virtual_servers, :os_template_id
  end

  def self.down
    add_column :virtual_servers, :os_template_id, :integer
  end
end
