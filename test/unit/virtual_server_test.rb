require 'test_helper'

class VirtualServerTest < ActiveSupport::TestCase

  def setup
    @server_101 =  virtual_servers(:server_101)
  end

  test "IPv6 address assignment" do
    @server_101.ip_address = "2001:0db8:85a3:0000:0000:8a2e:0370:7334"
    assert_valid @server_101

    @server_101.ip_address = "2001:db8:85a3:0:0:8a2e:370:7334"
    assert_valid @server_101

    @server_101.ip_address = "2001:db8:85a3::8a2e:370:7334"
    assert_valid @server_101

    @server_101.ip_address = "2001:db8:85a3::8a2e:370:7334 192.168.100.101"
    assert_valid @server_101

    @server_101.ip_address = "2001:db8:85a3::8a2e:370:7334 2001:0db8:85a3:0000:0000:8a2e:0370:7301"
    assert_valid @server_101
  end

  test "IPv4 address assignment" do
    @server_101.ip_address = "192.168.100.1"
    assert_valid @server_101

    @server_101.ip_address = "192.168.100.1 192.168.100.2"
    assert_valid @server_101
  end

  test "IPv4 address with netmask" do
    @server_101.ip_address = "10.0.0.1/16"
    assert_valid @server_101
  end

  test "Incorrect IP address assignment" do
    @server_101.ip_address = "not IP address"
    assert !@server_101.valid?

    @server_101.ip_address = "192.168.100"
    assert !@server_101.valid?
  end

  test "IPv4 nameserver assigment" do
    @server_101.nameserver = "192.168.0.254"
    assert_valid @server_101

    @server_101.nameserver = "192.168.100.254 192.168.101.254"
    assert_valid @server_101
  end

  test "IPv6 nameserver assigment" do
    @server_101.nameserver = "2001:db8:85a3::8a2e:370:7334"
    assert_valid @server_101

    @server_101.nameserver = "2001:db8:85a3::8a2e:370:7334 192.168.100.254"
    assert_valid @server_101
  end

  test "Incorrect IP for nameserver assignment" do
    @server_101.nameserver = "not IP address"
    assert !@server_101.valid?

    @server_101.nameserver = "192.168.100"
    assert !@server_101.valid?
  end

end
