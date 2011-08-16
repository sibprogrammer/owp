class CreateRoles < ActiveRecord::Migration
  def self.up
    create_table :roles do |t|
      t.string :name
      t.boolean :built_in
    end

    Role.create({ :name => 'superadmin', :built_in => true, :limit_backups => -1 })
    Role.create({ :name => 've_admin', :built_in => true, :limit_backups => -1 })
  end

  def self.down
    drop_table :roles
  end
end
