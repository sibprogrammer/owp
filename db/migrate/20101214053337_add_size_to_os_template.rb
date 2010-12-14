class AddSizeToOsTemplate < ActiveRecord::Migration
  def self.up
    add_column :os_templates, :size, :integer
  end

  def self.down
    remove_column :os_templates, :size
  end
end
