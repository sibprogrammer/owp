namespace :long_tasks do

  desc "Remove all records about old finished tasks"
  task :clear_old => :environment do
    limit_records = AppConfig.tasks.max_records
    total_records = BackgroundJob.count

    if total_records > limit_records
      task_record = BackgroundJob.find(:first, :order => 'id', :limit => 1, :offset => total_records - limit_records)
      BackgroundJob.delete_all(["id < ?", task_record.id])
    end
  end

  desc "Remove all records about finished tasks"
  task :clear_all => :environment do
    BackgroundJob.delete_all(["status != ?", BackgroundJob::RUNNING])
  end

end
