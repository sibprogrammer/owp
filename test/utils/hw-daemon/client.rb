require "xmlrpc/client"

username = 'admin'
password = 'secret'
server = XMLRPC::Client.new("ovz-vmx.lan", "/xmlrpc", 7767, nil, nil, username, password)

ok, result = server.call2("hwDaemon.version")
if ok then
  puts "Daemon version: #{result}"
else
  puts "Error:"
  puts result.faultCode
  puts result.faultString
end

ok, result = server.call2('hwDaemon.exec', 'cat', '/etc/issue')
puts "Exec code: #{result['exit_code']}; result: #{result['output']}"