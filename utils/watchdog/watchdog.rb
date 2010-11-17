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
    
    @debug = '1' == ENV['WATCHDOG_DEBUG']
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
    
    @sql = ActiveRecord::Base.connection.instance_variable_get(:@connection)
    @db_type = ('SQLite3::Database' == @sql.class.to_s) ? 'sqlite' : 'mysql'
    
    loop do
      begin
        exec_query('BEGIN;')
        collect_data
        rotate_data
        exec_query('COMMIT;')
      rescue Exception => e
        log "Exception: #{e.message}"
        log e.backtrace.inspect
      end
     
      # compress every hour
      compress_db if 0 == (@tick_counter % 60)
 
      sleep 60
      @tick_counter += 1
    end
  end
  
  def collect_data
    HardwareServer.all.each do |hardware_server|
      next unless hardware_server.rpc_client.ping
      @virtual_servers = hardware_server.virtual_servers.find_all_by_state('running')
      collect_beancounters(hardware_server)
      collect_memory_usage(hardware_server)
      collect_diskspace(hardware_server)
      collect_cpu_usage(hardware_server)
    end
  end
  
  def collect_beancounters(hardware_server)
    counters = hardware_server.rpc_client.exec('cat', "/proc/user_beancounters")['output'].split("\n")
      
    # remove table titles
    counters.shift; counters.shift
    
    current_ve_id = current_ve = nil
   
    saved_counters = BeanCounter.find_all_by_period_type(BeanCounter::PERIOD_PERMANENT)
 
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

        counter = saved_counters.find { |counter| counter.name == counter_info[0] and counter.virtual_server_id == current_ve.id }
        counter = add_counter(params) if !counter

        if counter.held != params[:held] or counter.maxheld != params[:maxheld] or counter.barrier != params[:barrier] or counter.limit != params[:limit] or counter.failcnt != params[:failcnt]
          if params[:failcnt].to_i > counter.failcnt.to_i
            exec_query(
              "INSERT INTO event_logs (`level`, `message`, `params`, `created_at`) VALUES (:level, :message, :params, :created_at)",
              { 
                :level => EventLog::WARN,
                :message => "virtual_server.counter_reached",
                :params => Marshal.dump({ :name => counter.name.upcase, :identity => current_ve.identity, :host => hardware_server.host, }),
                :created_at => DateTime.now.utc.strftime("%Y-%m-%d %H:%M:%S")
              }
            )
            log "Limit #{counter.name.upcase} was reached for virtual server #{current_ve.identity}" if @debug
            params[:alert] = 't'
          end
          update_counter(counter, params)
        else
          update_counter(counter, { :alert => 'f' }) if counter.alert
        end
      end
    end
  end
  
  def collect_memory_usage(hardware_server)
    ve_list = hardware_server.virtual_servers.find_all_by_state('running').map(&:identity).join(' ')
    command = "for VE in #{ve_list}; do echo $VE `vzctl exec $VE 'free -bo | sed \"1d;3d\"'`; done"
    counters = hardware_server.rpc_client.exec(command)['output'].split("\n")
    
    current_ve_id = current_ve = nil
    
    counters.each do |record|
      counter_info = record.split
      
      current_ve_id = counter_info[0].to_i
      current_ve = @virtual_servers.find { |ve| ve.identity == current_ve_id }
      
      if current_ve and current_ve_id == current_ve.identity
        info = {}
        info['total_bytes'] = counter_info[2].to_i
        info['free_bytes'] = counter_info[4].to_i
        info['used_bytes'] = counter_info[3].to_i
        add_counter({
          :name => '_memory',
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
        add_counter({
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
        
        counter = add_counter({
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
          add_counter({
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
  
  def add_counter(params)
    params[:created_at] = DateTime.now.utc.strftime("%Y-%m-%d %H:%M:%S")
    fields = params.keys.map{ |item| '`' + item.to_s + '`' }.join(', ')
    bindings = params.keys.map{ |item| ':' + item.to_s }.join(', ')
    exec_query("INSERT INTO bean_counters (#{fields}) VALUES (#{bindings})", params)
    BeanCounter.new(params)
  end
  
  def update_counter(counter, params)
    fields = []
    params.each { |key,value| fields << "`#{key.to_s}` = '#{value.to_s}'" }
    fields = fields.join(', ')
    exec_query("UPDATE bean_counters SET #{fields} WHERE id = ?", counter.id)
  end

  def rotate_data
    if 0 == (@tick_counter % 5)
      exec_query(
        'DELETE FROM bean_counters WHERE period_type = ? AND created_at < ?;',
        BeanCounter::PERIOD_MINUTE,
        (DateTime.now - 60.minute).utc.strftime("%Y-%m-%d %H:%M:%S")
      )
      log "Clean up of old bean counters." if @debug
    end
  end
 
  def compress_db
    begin
      exec_query('VACUUM;') if 'sqlite' == @db_type
      log "Database was compressed." if @debug
    rescue Exception => e
      log "Failed to compress database."
    end
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
    
    ActiveRecord::Base.logger.level = Logger::ERROR if @debug
  end
  
  def log(message)
    puts DateTime.now.to_s + ' ' + message
    STDOUT.flush
  end
  
  def exec_query(sql, *bind_vars)
    if 'sqlite' == @db_type
      @sql.execute(sql, *bind_vars)
    else
      if 0 == bind_vars.size
        @sql.query(sql)
      else
        if 1 == bind_vars.size and bind_vars[0].kind_of?(Hash)
          values = []
          while "" != (param = sql.match(/:[a-z_]*/).to_s) do
            sql.sub!(param, '?')
            values << bind_vars[0][param.sub(':','').to_sym]
          end
          statement = @sql.prepare(sql)
          statement.execute(*values)
        else
          statement = @sql.prepare(sql)
          statement.execute(*bind_vars)
        end
      end
    end
  end

end

WatchdogDaemon.new
