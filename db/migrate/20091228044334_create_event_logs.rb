class CreateEventLogs < ActiveRecord::Migration
  def self.up
    create_table :event_logs do |t|
      t.column :level, :integer
      t.column :message, :string
      t.column :params, :string
      t.column :created_at, :datetime
    end
  end

  def self.down
    drop_table :event_logs
  end
end
