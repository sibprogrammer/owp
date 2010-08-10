class CreateComments < ActiveRecord::Migration
  def self.up
    create_table :comments do |t|
      t.column :content, :text
      t.column :created_at, :datetime
      t.column :request_id, :integer
      t.column :user_id, :integer
    end
  end

  def self.down
    drop_table :comments
  end
end
