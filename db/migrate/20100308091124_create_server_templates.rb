class CreateServerTemplates < ActiveRecord::Migration
  def self.up
    create_table :server_templates do |t|
      t.column :name, :string, :limit => 255
      t.column :hardware_server_id, :integer
    end
  end

  def self.down
    drop_table :server_templates
  end
end
