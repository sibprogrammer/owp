class CreatePermissions < ActiveRecord::Migration
  def self.up
    create_table :permissions do |t|
      t.string :name
    end

    Permission.create({ :name => 'manage_hardware_servers' })
    Permission.create({ :name => 'use_ve_console' })
    Permission.create({ :name => 'backup_ve' })
    Permission.create({ :name => 'reinstall_ve' })
    Permission.create({ :name => 'handle_requests' })
    Permission.create({ :name => 'create_requests' })
    Permission.create({ :name => 'view_tasks' })
    Permission.create({ :name => 'view_logs' })
    Permission.create({ :name => 'manage_logs' })
    Permission.create({ :name => 'manage_users' })
  end

  def self.down
    drop_table :permissions
  end
end
