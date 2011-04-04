class CreateIpPools < ActiveRecord::Migration
  def self.up
    create_table :ip_pools do |t|
      t.string :first_ip
      t.string :last_ip
      t.integer :hardware_server_id
    end
  end

  def self.down
    drop_table :ip_pools
  end
end
