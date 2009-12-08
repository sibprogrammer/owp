require "xmlrpc/client"

class HwDaemonClient
  
  def initialize(host, auth_key)
    @host = host
    @auth_key = auth_key
    @rpc_client = XMLRPC::Client.new3({
      :host => @host,
      :path => "/xmlrpc",
      :port => HW_DAEMON_PORT, 
      :user => 'admin', 
      :password => @auth_key,
      :timeout => 5 * 60
    })
  end
  
  def exec(command, args = '')
    RAILS_DEFAULT_LOGGER.info "Executing command: #{command} #{args}"
    rpc_call('hwDaemon.exec', command, args)
  end  
  
  def daemon_version
    rpc_call('hwDaemon.version')
  end
  
  private
  
  def rpc_call(*args)
    ok, result = @rpc_client.call2(*args)
    
    if ok then
      return result
    else
      RAILS_DEFAULT_LOGGER.err "XML-RPC call error: #{result.faultCode}; #{result.faultString}"
    end
  end
  
end