class CreateBackups < ActiveRecord::Migration
  def self.up
    create_table :backups do |t|
      t.column :name, :string
      t.column :description, :string
      t.column :size, :integer
      t.column :virtual_server_id, :integer
    end
  end

  def self.down
    drop_table :backups
  end
end
