class AddCpuLimitsToVirtualServer < ActiveRecord::Migration
  def self.up
    add_column :virtual_servers, :cpu_units, :integer
    add_column :virtual_servers, :cpu_limit, :integer
    add_column :virtual_servers, :cpus, :integer
  end

  def self.down
    remove_column :virtual_servers, :cpus
    remove_column :virtual_servers, :cpu_limit
    remove_column :virtual_servers, :cpu_units
  end
end
