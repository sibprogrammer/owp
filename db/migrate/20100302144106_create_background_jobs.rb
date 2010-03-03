class CreateBackgroundJobs < ActiveRecord::Migration
  def self.up
    create_table :background_jobs do |t|
      t.column :description, :string
      t.column :params, :string
      t.column :status, :integer
    end
  end

  def self.down
    drop_table :background_jobs
  end
end
