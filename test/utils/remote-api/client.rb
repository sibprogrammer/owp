#!/usr/bin/env ruby

require 'net/http'
require 'rexml/document'

host = 'host'
port = 3000
user = 'admin'
password = 'password'
api_method = '/api/hardware_servers/list'

Net::HTTP.start(host, port) do |http|
  request = Net::HTTP::Get.new(api_method)
  request.basic_auth user, password
  response = http.request(request)
  result = response.body

  print result

  doc = REXML::Document.new(result)
  doc.elements.each('//hardware_server/host') do |element|
    print "server: #{element.text}\n"
  end
end
