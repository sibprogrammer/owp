require 'webrick'
require 'xmlrpc/server.rb'

DAEMON_VERSION = '1.0'
CURRENT_DIR = File.expand_path(File.dirname(__FILE__)) + '/'
CONFIG_FILE = CURRENT_DIR + 'hw-daemon.ini';
PID_FILE = CURRENT_DIR + 'hw-daemon.pid';
LOG_FILE = CURRENT_DIR + 'hw-daemon.log'
$SERVER_ADDRESS = "0.0.0.0"
$SERVER_PORT = 7767
$AUTH_KEY = ""
$DEBUG = false
$LOG = WEBrick::Log.new(LOG_FILE)

class HwDaemonApiHandler < XMLRPC::WEBrickServlet  
  
  def version
     DAEMON_VERSION
  end
  
  def exec(command, args = '')
    output = `#{command} #{args}`
    exit_code = $?
    $LOG.debug("Exec command: #{command} #{args}; code: #{exit_code}; output:\n#{output}")
    { 'exit_code' => exit_code.to_i, 'output' => output }
  end
  
  def service(request, response)
    WEBrick::HTTPAuth.basic_auth(request, response, '') do |user, password|
      user == 'admin' && password == $AUTH_KEY
    end
     
    super
  end
  
  def handle(method, *params)
    $LOG.debug("Execute method: #{method}")    
    super
  end
  
end

class HwDaemonUtil
  
  def initialize
    if (0 == ARGV.size)
      do_help
    end

    load_config
    $LOG.level = WEBrick::Log::DEBUG if $DEBUG
    
    command = ARGV[0]

    case command
      when 'start'
        do_start
      when 'stop'
        do_stop
      when 'restart'
        do_restart
      when 'status'
        do_status
      else
        do_help
    end
  end
  
  def do_start
    puts "Starting the daemon..."
    
    servlet = HwDaemonApiHandler.new
    servlet.add_handler("hwDaemon", servlet)   
    servlet.set_default_handler do |name, *args|
      raise XMLRPC::FaultException.new(-99, "Method #{name} missing or wrong number of parameters!")
    end
    
    server = WEBrick::HTTPServer.new(
      :Port => $SERVER_PORT,
      :BindAddress => $SERVER_ADDRESS,
      :Logger => $LOG
    )
    
    server.mount('/xmlrpc', servlet)
    
    ['INT', 'TERM'].each { |signal| trap(signal) { server.shutdown } }

    WEBrick::Daemon.start do
      write_pid_file
      server.start
      delete_pid_file
    end
  end
  
  def do_stop
    if (File.exists?(PID_FILE))
      pid = File.read(PID_FILE)
      $LOG.debug("Killing process with PID #{pid.to_i}")
      Process.kill('TERM', pid.to_i)
    end
    
    puts "Daemon was stopped."
  end
  
  def do_restart
    do_stop
    do_start
  end
  
  def do_status
    if (File.exists?(PID_FILE))
      puts "Daemon is running."
    else
      puts "Daemon is stopped."
      exit(1)
    end
  end
  
  def do_help
    puts "Usage: ruby hw-daemon.rb (start|stop|restart|status|help)"
    exit(1)
  end
  
  def load_config    
    file = File.new(CONFIG_FILE, 'r')
    
    while (line = file.gets)
      key, value = line.split('=', 2).each { |v| v.strip! }
      
      case key
        when 'address'
          $SERVER_ADDRESS = value
        when 'port'
          $SERVER_PORT = value
        when 'key'
          $AUTH_KEY = value
        when 'debug'
          $DEBUG = true if value == 'on'          
      end
    end
    
    file.close
  end
  
  def write_pid_file
    open(PID_FILE, "w") { |file| file.write(Process.pid) } 
  end
  
  def delete_pid_file
    if File.exists?(PID_FILE)
      File.unlink PID_FILE
    end
  end
  
end

HwDaemonUtil.new

