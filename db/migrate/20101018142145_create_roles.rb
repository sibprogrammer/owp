class CreateRoles < ActiveRecord::Migration
  def self.up
    create_table :roles do |t|
      t.string :name
      t.boolean :built_in
    end
    
    Role.create({ :name => 'superadmin', :built_in => true })
    Role.create({ :name => 've_admin', :built_in => true })
  end

  def self.down
    drop_table :roles
  end
end
