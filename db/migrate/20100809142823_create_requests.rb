class CreateRequests < ActiveRecord::Migration
  def self.up
    create_table :requests do |t|
      t.column :subject, :string, :limit => 255
      t.column :content, :text
      t.column :opened, :boolean, :default => true
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :user_id, :integer
    end
  end

  def self.down
    drop_table :requests
  end
end
