#!/usr/bin/env ruby

require 'date'

CURRENT_DIR = File.expand_path(File.dirname(__FILE__)) + '/'
PID_FILE = CURRENT_DIR + 'watchdog.pid';
LOG_FILE = CURRENT_DIR + 'watchdog.log'

class WatchdogDaemon
  
  def initialize
    check_environment
    
    do_help if (0 == ARGV.size)
    
    case ARGV[0]
      when 'start' then do_start
      when 'stop' then do_stop
      when 'restart' then do_restart
      when 'status' then do_status
      else do_help
    end
  end
  
  def check_environment
    if RUBY_VERSION !~ /1\.8\..+/
      puts "Ruby #{RUBY_VERSION} is not supported."
      exit(1)
    end
  end
  
  def do_start
    puts "Starting watchdog daemon..."
    
    raise 'Failed to fork child.' if (pid = fork) == -1
    exit unless pid.nil?
    
    Process.setsid
    raise 'Failed to create daemon.' if (pid = fork) == -1
    exit unless pid.nil?
    
    Signal.trap('HUP', 'IGNORE')
    ['INT', 'TERM'].each { |signal| trap(signal) { shutdown } }
    
    STDIN.reopen '/dev/null'
    STDOUT.reopen LOG_FILE, 'a'
    STDERR.reopen STDOUT
    
    write_pid_file
    task
    delete_pid_file
  end
  
  def do_stop
    if (File.exists?(PID_FILE))
      pid = File.read(PID_FILE)
      begin
        Process.kill('TERM', pid.to_i)
      rescue
        delete_pid_file
      end
    end
    
    puts "Watchdog daemon was stopped."
  end
  
  def do_restart
    do_stop
    do_start
  end
  
  def do_status
    if (File.exists?(PID_FILE))
      puts "Watchdog daemon is running."
    else
      puts "Watchdog daemon is stopped."
      exit(1)
    end
  end
  
  def do_help
    puts "Usage: ruby watchdog.rb (start|stop|restart|status|help)"
    exit(1)
  end
  
  def write_pid_file
    log "Daemon pid: #{Process.pid}"
    open(PID_FILE, "w") { |file| file.write(Process.pid) } 
  end
  
  def delete_pid_file
    File.unlink PID_FILE if File.exists?(PID_FILE)
  end
  
  def task
    @tick_counter = 1
    load_rails_env
    
    loop do
      begin
        collect_data
      rescue Exception => e
        log "Exception: #{e.message}"
        log e.backtrace.inspect
      end
      rotate_data
      sleep 60
      @tick_counter += 1
    end
  end
  
  def collect_data
    HardwareServer.all.each do |hardware_server|
      next unless hardware_server.rpc_client.ping
      @virtual_servers = hardware_server.virtual_servers.find_all_by_state('running')
      collect_beancounters(hardware_server)
      collect_diskspace(hardware_server)
      collect_cpu_usage(hardware_server)
    end
  end
  
  def collect_beancounters(hardware_server)
    counters = hardware_server.rpc_client.exec('cat', "/proc/user_beancounters")['output'].split("\n")
      
    # remove table titles
    counters.shift; counters.shift
    
    current_ve_id = current_ve = nil
    
    counters.each do |record|
      counter_info = record.split
      if counter_info[0] =~ /^\d+:$/
        current_ve_id = counter_info[0].gsub(/[^\d]/, '').to_i
        current_ve = @virtual_servers.find { |ve| ve.identity == current_ve_id }
        counter_info.shift
      end
      
      if current_ve and current_ve_id == current_ve.identity and 'dummy' != counter_info[0]
        params = {
          :name => counter_info[0],
          :virtual_server_id => current_ve.id,
          :held => counter_info[1],
          :maxheld => counter_info[2],
          :barrier => counter_info[3],
          :limit => counter_info[4],
          :failcnt => counter_info[5],
          :period_type => BeanCounter::PERIOD_PERMANENT,
        }

        counter = BeanCounter.find_last_by_name_and_virtual_server_id_and_period_type(counter_info[0], current_ve.id, BeanCounter::PERIOD_PERMANENT)
        counter = BeanCounter.create(params) if !counter

        if counter.held != params[:held] or counter.maxheld != params[:maxheld] or counter.barrier != params[:barrier] or counter.limit != params[:limit] or counter.failcnt != params[:failcnt]
          if counter.failcnt != params[:failcnt]
            EventLog.error("virtual_server.counter_reached", {
              :name => counter.name.upcase,
              :identity => current_ve.identity,
              :host => hardware_server.host,
            })
            params[:alert] = true
          end
          counter.update_attributes(params)
        else
          counter.update_attribute(:alert, false) if counter.alert
        end

        if 'privvmpages' == params[:name]
          params[:period_type] = BeanCounter::PERIOD_MINUTE
          BeanCounter.create(params)
        end 
      end
    end
  end
  
  def collect_diskspace(hardware_server)
    ve_list = hardware_server.virtual_servers.find_all_by_state('running').map(&:identity).join(' ')
    command = "for VE in #{ve_list}; do echo $VE `vzctl exec $VE 'stat -c \"%s %b %a\" -f /'`; done"
    counters = hardware_server.rpc_client.exec(command)['output'].split("\n")
    
    current_ve_id = current_ve = nil
    
    counters.each do |record|
      counter_info = record.split
      
      current_ve_id = counter_info[0].to_i
      current_ve = @virtual_servers.find { |ve| ve.identity == current_ve_id }
      
      if current_ve and current_ve_id == current_ve.identity
        info = {}
        info['block_size'] = counter_info[1].to_i
        info['total_bytes'] = info['block_size'] * counter_info[2].to_i
        info['free_bytes'] = info['block_size'] * counter_info[3].to_i
        info['used_bytes'] = info['total_bytes'] - info['free_bytes']
        BeanCounter.create({
          :name => '_diskspace',
          :virtual_server_id => current_ve.id,
          :held => info['used_bytes'].to_s,
          :maxheld => '',
          :barrier => '',
          :limit => info['total_bytes'].to_s,
          :failcnt => '',
          :period_type => BeanCounter::PERIOD_MINUTE,
        })
      end
    end
  end

  def collect_cpu_usage(hardware_server)
    ve_list = hardware_server.virtual_servers.find_all_by_state('running').map(&:identity).join(' ')
    command = "for VE in #{ve_list}; do echo $VE `vzctl exec $VE 'cat /proc/stat | head -1'`; done"
    counters = hardware_server.rpc_client.exec(command)['output'].split("\n")

    counters.each do |record|
      counter_info = record.split
      next if counter_info.size < 6

      current_ve_id = counter_info[0].to_i
      current_ve = @virtual_servers.find { |ve| ve.identity == current_ve_id }

      if current_ve and current_ve_id == current_ve.identity
        prev_counter = BeanCounter.find_last_by_name_and_virtual_server_id('_cpu', current_ve.id)
        
        counter = BeanCounter.create({
          :name => '_cpu',
          :virtual_server_id => current_ve.id,
          :held => counter_info[5],
          :maxheld => '',
          :barrier => '',
          :limit => counter_info[2,4].map(&:to_i).sum.to_s,
          :failcnt => '',
          :period_type => BeanCounter::PERIOD_MINUTE,
        })
        
        if prev_counter
          cpu_usage = BeanCounter.create({
            :name => '_cpu_usage',
            :virtual_server_id => current_ve.id,
            :held => (100 - ((counter.held.to_i - prev_counter.held.to_i) * 100 / (counter.limit.to_i - prev_counter.limit.to_i))).to_s,
            :maxheld => '',
            :barrier => '',
            :limit => '100',
            :failcnt => '',
            :period_type => BeanCounter::PERIOD_MINUTE,
          })
        end
      end
    end
  end  

  def rotate_data
    BeanCounter.delete_all([
      'period_type = ? AND created_at < ?',
      BeanCounter::PERIOD_MINUTE,
      (DateTime.now - 60.minute).utc
    ])
    
    # compress every hour
    return unless 0 == (@tick_counter % 60)
    # TODO: check DB engine
    BeanCounter.connection.execute("VACUUM;")
  end
  
  def shutdown
    log "Daemon shutdown."
    delete_pid_file
    exit(0)
  end
  
  def load_rails_env
    environment = (2 == ARGV.size) ? ARGV[1] : 'production'
    
    require File.dirname(__FILE__) + '/../../config/boot'
    ENV["RAILS_ENV"] = environment
    RAILS_ENV.replace(environment) if defined?(RAILS_ENV)
    require RAILS_ROOT + '/config/environment'
    
    ActiveRecord::Base.logger.level = Logger::ERROR if '1' != ENV['WATCHDOG_DEBUG']
  end
  
  def log(message)
    puts DateTime.now.to_s + ' ' + message
    STDOUT.flush
  end

end

WatchdogDaemon.new
