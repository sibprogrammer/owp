class CreateHardwareServers < ActiveRecord::Migration
  def self.up
    create_table :hardware_servers do |t|
      t.column :host, :string, :limit => 255
      t.column :auth_key, :string, :limit => 255
      t.column :description, :string, :limit => 255
    end

    add_index :hardware_servers, :host, :unique => true
  end

  def self.down
    drop_table :hardware_servers
  end
end
