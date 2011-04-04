require 'test_helper'

class IpPoolTest < ActiveSupport::TestCase

  test "IPv4 simple range" do
    ip_pool =  ip_pools(:ip_pool_1)
    assert_valid ip_pool
  end

  test "Bad IPv4 range" do
    ip_pool =  ip_pools(:ip_pool_2)
    ip_pool.last_ip = '192.168.0.1'
    assert !ip_pool.valid?
  end

  test "Range details" do
    ip_pool =  ip_pools(:ip_pool_1)
    assert 10 == ip_pool.total_ips
    assert 10 == ip_pool.free_ips
    assert 0 == ip_pool.used_ips
  end

end
