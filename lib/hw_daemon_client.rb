require "xmlrpc/client"

class HwDaemonClient
  
  def initialize(host, auth_key)
    @host = host
    @auth_key = auth_key
    @rpc_client = XMLRPC::Client.new3({
      :host => @host,
      :path => "/xmlrpc",
      :port => AppConfig.hw_daemon.port,
      :user => 'admin', 
      :password => @auth_key,
      :timeout => 5 * 60
    })
  end
  
  def exec(command, args = '')
    RAILS_DEFAULT_LOGGER.info "Executing command: #{command} #{args}"
    rpc_call('hwDaemon.exec', command, args)
  end
  
  def job(command, args = '')
    RAILS_DEFAULT_LOGGER.info "Scheduling job: #{command} #{args}"
    rpc_call('hwDaemon.job', command, args)
  end
  
  def job_status(job_id)
    rpc_call('hwDaemon.job_status', job_id)
  end
  
  def daemon_version
    rpc_call('hwDaemon.version')
  end
  
  def ping
    rpc_call('hwDaemon.version')
  end
  
  private
  
  def rpc_call(*args)
    begin
      ok, result = @rpc_client.call2(*args)
    rescue RuntimeError => error
      RAILS_DEFAULT_LOGGER.error "XML-RPC runtime error: #{error}"
      return false
    end
    
    if ok then
      return result
    else
      RAILS_DEFAULT_LOGGER.error "XML-RPC call error: #{result.faultCode}; #{result.faultString}"
    end
  end
  
end