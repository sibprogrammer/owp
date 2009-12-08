class CreateVirtualServers < ActiveRecord::Migration
  def self.up
    create_table :virtual_servers do |t|
      t.column :identity, :integer
      t.column :ip_address, :string, :limit => 255
      t.column :host_name, :string, :limit => 255
      t.column :state, :string, :limit => 20
      t.column :hardware_server_id, :integer
      t.column :os_template_id, :integer
    end
  end

  def self.down
    drop_table :virtual_servers
  end
end
