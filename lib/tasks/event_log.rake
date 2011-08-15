namespace :event_log do

  desc "Clear old events records"
  task :clear_old => :environment do
    limit_records = AppConfig.log.max_records
    total_records = EventLog.count

    if total_records > limit_records
      log_record = EventLog.find(:first, :order => 'id', :limit => 1, :offset => total_records - limit_records)
      EventLog.delete_all(["id < ?", log_record.id])
    end
  end

  desc "Clear all events records"
  task :clear_all => :environment do
    EventLog.delete_all
  end

end
