namespace :cron do

  desc "Perfrom all scheduled tasks"
  task :all => :environment do
    puts "Loading #{Rails.env} environment..."
    do_scheduled_backups
    do_clear_old_logs
  end

  desc "Create scheduled backups"
  task :backups => :environment do
    do_scheduled_backups
  end

  desc "Clear old logs"
  task :logs => :environment do
    do_clear_old_logs
  end

  private

    def do_scheduled_backups
      puts "Create scheduled backups..."
      VirtualServer.daily_backed_up.each do |virtual_server|
        begin
          virtual_server.create_daily_backup
        rescue Exception => e
          puts "Unable to create backup for server with internal id ##{virtual_server.id}: #{e.message}"
        end
      end
    end

    def do_clear_old_logs
      puts "Clear old logs..."
      Rake::Task['event_log:clear_old'].invoke
    end

end
