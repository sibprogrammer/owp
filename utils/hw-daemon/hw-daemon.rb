#!/usr/bin/env ruby

require 'webrick'
require 'xmlrpc/server.rb'

# workaround for clients with incorrect DNS records
Socket.do_not_reverse_lookup = true

ENV['PATH'] += ':/usr/sbin:/usr/local/sbin'

DAEMON_VERSION = '1.3'
CURRENT_DIR = File.expand_path(File.dirname(__FILE__)) + '/'
CONFIG_FILE = CURRENT_DIR + 'hw-daemon.ini'
PID_FILE = CURRENT_DIR + 'hw-daemon.pid'
LOG_FILE = CURRENT_DIR + 'hw-daemon.log'
SSL_CERT_FILE = CURRENT_DIR + "/certs/server.crt"
SSL_PKEY_FILE = CURRENT_DIR + "/certs/server.key"

$SERVER_ADDRESS = "0.0.0.0"
$SERVER_PORT = 7767
$AUTH_KEY = ""
$DEBUG = false
$LOG = WEBrick::Log.new(LOG_FILE)

$SSL_ENABLE = false
$SSL_CERT = ''
$SSL_PKEY = ''

$THREADS = {}

class HwDaemonApiHandler < XMLRPC::WEBrickServlet

  def version
     DAEMON_VERSION
  end

  def exec(command, args = '')
    output = `#{command} #{args} 2>&1`
    exit_code = $?
    $LOG.debug("Exec command: #{command} #{args}; code: #{exit_code}; output:\n#{output}")
    { 'exit_code' => exit_code >> 8, 'output' => output }
  end

  def job(command, args = '')
    job_id = generate_id

    t = Thread.new do
      result = self.exec(command, args)
      $THREADS[job_id]['result'] = result
    end

    $THREADS[job_id] = { 'thread' => t }

    { 'job_id' => job_id }
  end

  def job_status(job_id)
    found = $THREADS.has_key?(job_id)
    result = ''

    if found
      alive = $THREADS[job_id]['thread'].alive?
      result = $THREADS[job_id]['result'] unless alive
    end

    { 'found' => found, 'alive' => alive, 'result' => result }
  end

  def write_file(filename, content)
    File.open(filename, 'w') { |file| file.write(content) }
    $LOG.debug("Writing file: #{filename}")
    File.exists?(filename)
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

  private

  def generate_id
    symbols = [('0'..'9'),('a'..'f')].map{ |i| i.to_a }.flatten
    (1..32).map{ symbols[rand(symbols.length)] }.join
  end

end

class HwDaemonUtil

  def initialize
    check_environment

    if (0 == ARGV.size)
      do_help
    end

    load_config
    $LOG.level = WEBrick::Log::DEBUG if $DEBUG

    if $SSL_ENABLE
      require 'webrick/https'
      $SSL_CERT = OpenSSL::X509::Certificate.new(File.open(SSL_CERT_FILE).read) if File.readable?(SSL_CERT_FILE)
      $SSL_PKEY = OpenSSL::PKey::RSA.new(File.open(SSL_PKEY_FILE).read) if File.readable?(SSL_PKEY_FILE)
    end

    command = ARGV[0]

    case command
      when 'start'
        do_start
      when 'stop'
        exit do_stop
      when 'restart'
        do_restart
      when 'status'
        do_status
      else
        do_help
    end
  end

  def puts_ok(message)
    puts "\033[00;32m[OK]\033[00m " + message
  end

  def puts_fail(message)
    puts "\033[00;31m[FAIL]\033[00m " + message
  end

  def check_environment
    if RUBY_VERSION !~ /1\.8\..+/
      puts "Ruby #{RUBY_VERSION} is not supported."
      exit(1)
    end

    if !File.exists?('/proc/vz/version')
      puts "Daemon should be run on the server with OpenVZ."
      exit(1)
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
      :Logger => $LOG,
      :SSLEnable => $SSL_ENABLE,
      :SSLVerifyClient => ($SSL_ENABLE ? OpenSSL::SSL::VERIFY_NONE : nil),
      :SSLCertificate => $SSL_CERT,
      :SSLPrivateKey => $SSL_PKEY,
      :SSLCertName => [ [ "CN", WEBrick::Utils::getservername ] ]
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
      pid = File.read(PID_FILE).to_i

      begin
        Process.kill(0, pid)
      rescue
        $LOG.debug("Unable to find process with PID #{pid}")
        puts_fail "Daemon probably died."
        delete_pid_file
        return 1
      end

      $LOG.debug("Killing process with PID #{pid}")

      begin
        Process.kill('TERM', pid)
      rescue
        $LOG.debug("Unable to kill process with PID #{pid}")
        puts_fail "Unable to stop daemon."
      end
    end

    puts_ok "Daemon was stopped."
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
        puts_fail "Daemon probably died."
        exit 1
      end

      puts_ok "Daemon is running."
    else
      puts_fail "Daemon is stopped."
      exit 1
    end
  end

  def do_help
    puts "Usage: ruby hw-daemon.rb (start|stop|restart|status|help)"
    exit 1
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
        when 'ssl'
          $SSL_ENABLE = true if value == 'on'
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
