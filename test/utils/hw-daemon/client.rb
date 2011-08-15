require "xmlrpc/client"

username = 'admin'
password = 'secret'
server = XMLRPC::Client.new("127.0.0.1", "/xmlrpc", 7767, nil, nil, username, password)

def print_status(ok, result)
  if ok then
    puts "Result: #{result.inspect}"
  else
    puts "Error:"
    puts result.faultCode
    puts result.faultString
  end
end

ok, result = server.call2("hwDaemon.version")
print_status(ok, result)

ok, result = server.call2('hwDaemon.exec', 'cat', '/etc/issue')
print_status(ok, result)

ok, result = server.call2('hwDaemon.job', 'sleep', '1')
print_status(ok, result)
job_id = result['job_id']

ok, result = server.call2('hwDaemon.job_status', job_id)
print_status(ok, result)

`sleep 3`

ok, result = server.call2('hwDaemon.job_status', job_id)
print_status(ok, result)
