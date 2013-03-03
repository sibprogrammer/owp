#!/usr/bin/env ruby

require 'drb/drb'
require 'date'
require 'ostruct'

CURRENT_DIR = File.expand_path(File.dirname(__FILE__)) + '/'
PID_FILE = CURRENT_DIR + 'watchdog.pid';
LOG_FILE = CURRENT_DIR + 'watchdog.log'
SERVER_URI = "druby://localhost:7787"
WATCHDOG_DAEMON = true

class WatchdogService

  def initialize
    @ve_counters = {}
    @hw_params = {}
  end

  def alive
    true
  end

  def get_ve_counter(name, server_id)
    key = server_id.to_s + name
    return false unless @ve_counters.has_key?(key)
    OpenStruct.new(@ve_counters[key].last)
  end

  def remove_ve_counter(name, server_id)
    key = server_id.to_s + name
    @ve_counters.delete(key)
  end

  def get_ve_counters_queue(name, server_id)
    key = server_id.to_s + name
    return [] unless @ve_counters.has_key?(key)
    @ve_counters[key]
  end

  def get_hw_param(name, server_id)
    key = server_id.to_s + name
    return nil unless @hw_params.has_key?(key)
    @hw_params[key]
  end

  def collect_data
    HardwareServer.all.each do |hardware_server|
      next unless hardware_server.rpc_client.ping
      @virtual_servers = hardware_server.virtual_servers.find_all_by_state('running')
      collect_beancounters(hardware_server)
      collect_memory_usage(hardware_server)
      collect_diskspace(hardware_server)
      collect_cpu_usage(hardware_server)
      collect_hw_parameters(hardware_server)
      collect_states(hardware_server)
    end
  end

  def collect_states(hardware_server)
    ves_on_server = hardware_server.rpc_client.exec('vzlist', '-a -H -o veid,status')['output'].split("\n")
    # skip error lines
    ves_on_server = ves_on_server.find_all { |item| item =~ /^\s+\d+/ }

    ves_on_server.each do |vzlist_entry|
      ve_id, ve_state = vzlist_entry.split
      current_ve = hardware_server.virtual_servers.find_by_identity(ve_id)
      if current_ve
        add_ve_counter({
          :name => 'state',
          :virtual_server_id => current_ve.id,
          :state => ve_state,
        })
      end
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
        current_ve_id = counter_info[0].gsub(/[^\d]/, '')
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
        }

        counter = get_ve_counter(params[:name], current_ve.id)
        counter = add_ve_counter(params) if !counter
        params[:alert] = (params[:failcnt].to_i > counter.failcnt.to_i)

        add_ve_counter(params)
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
      next if counter_info.size < 5

      current_ve_id = counter_info[0]
      current_ve = @virtual_servers.find { |ve| ve.identity == current_ve_id }

      if current_ve and current_ve_id == current_ve.identity
        info = {}
        info['total_bytes'] = counter_info[2].to_i
        info['free_bytes'] = counter_info[4].to_i
        info['used_bytes'] = counter_info[3].to_i
        add_ve_counter({
          :name => '_memory',
          :virtual_server_id => current_ve.id,
          :held => info['used_bytes'].to_s,
          :limit => info['total_bytes'].to_s,
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
      next if counter_info.size < 4

      current_ve_id = counter_info[0]
      current_ve = @virtual_servers.find { |ve| ve.identity == current_ve_id }

      if current_ve and current_ve_id == current_ve.identity
        info = {}
        info['block_size'] = counter_info[1].to_i
        info['total_bytes'] = info['block_size'] * counter_info[2].to_i
        info['free_bytes'] = info['block_size'] * counter_info[3].to_i
        info['used_bytes'] = info['total_bytes'] - info['free_bytes']
        add_ve_counter({
          :name => '_diskspace',
          :virtual_server_id => current_ve.id,
          :held => info['used_bytes'].to_s,
          :limit => info['total_bytes'].to_s,
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

      current_ve_id = counter_info[0]
      current_ve = @virtual_servers.find { |ve| ve.identity == current_ve_id }

      if current_ve and current_ve_id == current_ve.identity
        prev_counter = get_ve_counter('_cpu', current_ve.id)

        counter = add_ve_counter({
          :name => '_cpu',
          :virtual_server_id => current_ve.id,
          :held => counter_info[5],
          :limit => counter_info[2,4].map(&:to_i).sum.to_s,
        })

        if prev_counter
          add_ve_counter({
            :name => '_cpu_usage',
            :virtual_server_id => current_ve.id,
            :held => (100 - ((counter.held.to_i - prev_counter.held.to_i) * 100 / (counter.limit.to_i - prev_counter.limit.to_i))).to_s,
            :limit => '100',
          })
        end
      end
    end
  end

  def collect_hw_parameters(hardware_server)
    os_version = hardware_server.rpc_client.exec('uname', '-srm')['output']
    add_hw_parameter(hardware_server.id, 'os_version', os_version)

    cpu_load_average = hardware_server.rpc_client.exec('cat', '/proc/loadavg')['output'].split[0..2]
    add_hw_parameter(hardware_server.id, 'cpu_load_average', cpu_load_average)

    memory_usage = get_hw_memory_usage(hardware_server)
    add_hw_parameter(hardware_server.id, 'memory_usage', memory_usage)

    disk_usage = get_hw_disk_usage(hardware_server)
    add_hw_parameter(hardware_server.id, 'disk_usage', disk_usage)
  end

  def get_hw_memory_usage(hardware_server)
    raw_info = hardware_server.rpc_client.exec('free', '-bo')['output'].split("\n")[1].split
    info = {}
    info['total_bytes'] = raw_info[1].to_i
    info['free_bytes'] = raw_info[3].to_i + raw_info[5].to_i + raw_info[6].to_i
    info['used_bytes'] = info['total_bytes'] - info['free_bytes']
    info['usage_percent'] = (info['used_bytes'].to_f / info['total_bytes'].to_f * 100).to_i
    info
  end

  def get_hw_disk_usage(hardware_server)
    raw_info = hardware_server.rpc_client.exec('df', '-lP -k')['output']
    raw_info.split("\n").find_all{ |item| item =~ /^\// }.map{ |item|
      item = item.split
      {
        'partition' => item[0],
        'total_bytes' => item[1].to_i * 1024,
        'used_bytes' => item[2].to_i * 1024,
        'free_bytes' => item[3].to_i * 1024,
        'usage_percent' => item[4].to_i,
        'mount_point' => item[5],
      }
    }
  end

  def add_ve_counter(counter)
    counter[:created_at] = DateTime.now

    key = counter[:virtual_server_id].to_s + counter[:name]
    @ve_counters[key] = [] unless @ve_counters.has_key?(key)
    @ve_counters[key] << counter

    # store last 60 values
    @ve_counters[key].shift if @ve_counters[key].size > 60

    OpenStruct.new(counter)
  end

  def add_hw_parameter(server_id, name, value)
    key = server_id.to_s + name
    @hw_params[key] = value
  end

end

class WatchdogDaemon

  def initialize
    check_environment

    do_help if (0 == ARGV.size)

    case ARGV[0]
      when 'start' then do_start
      when 'stop' then exit do_stop
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

  def puts_ok(message)
    puts "\033[00;32m[OK]\033[00m " + message
  end

  def puts_fail(message)
    puts "\033[00;31m[FAIL]\033[00m " + message
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

    load_rails_env
    watchdog = WatchdogService.new
    DRb.start_service(SERVER_URI, watchdog)
    start_worker(watchdog)

    delete_pid_file
  end

  def do_stop
    if (File.exists?(PID_FILE))
      pid = File.read(PID_FILE).to_i

      begin
        Process.kill(0, pid)
      rescue
        puts_fail "Watchdog daemon probably died."
        delete_pid_file
        return 1
      end

      begin
        Process.kill('TERM', pid)
      rescue
        puts_fail "Unable to stop watchdog daemon."
      end
    end

    puts_ok "Watchdog daemon was stopped."
    return 0
  end

  def do_restart
    do_stop
    do_start
  end

  def do_status
    if (File.exists?(PID_FILE))
      pid = File.read(PID_FILE).to_i

      begin
        Process.kill(0, pid)
      rescue
        puts_fail "Watchdog daemon probably died."
        exit 1
      end

      puts_ok "Watchdog daemon is running."
    else
      puts_fail "Watchdog daemon is stopped."
      exit 1
    end
  end

  def do_help
    puts "Usage: ruby watchdog.rb (start|stop|restart|status|help)"
    exit 1
  end

  def write_pid_file
    log "Daemon pid: #{Process.pid}"
    open(PID_FILE, "w") { |file| file.write(Process.pid) }
  end

  def delete_pid_file
    File.unlink PID_FILE if File.exists?(PID_FILE)
  end

  def start_worker(watchdog)
    @tick_counter = 1

    loop do
      begin
        watchdog.collect_data
      rescue Exception => e
        log "Exception: #{e.message}"
        log e.backtrace.inspect
      end

      sleep 60
      @tick_counter += 1
    end
  end

  def shutdown
    log "Daemon shutdown."
    delete_pid_file
    exit(0)
  end

  def log(message)
    puts DateTime.now.to_s + ' ' + message
    STDOUT.flush
  end

  def load_rails_env
    environment = (2 == ARGV.size) ? ARGV[1] : 'production'

    require File.dirname(__FILE__) + '/../../config/boot'
    ENV["RAILS_ENV"] = environment
    RAILS_ENV.replace(environment) if defined?(RAILS_ENV)
    require RAILS_ROOT + '/config/environment'

    ActiveRecord::Base.logger.level = Logger::ERROR if @debug
  end

end

WatchdogDaemon.new
