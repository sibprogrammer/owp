require 'test_helper'

class ApplicationHelperTest < ActiveSupport::TestCase
  include ApplicationHelper

  test "diskspace limit conversion" do
    assert_equal 2, get_diskspace_mb("2M")
    assert_equal 1, get_diskspace_mb("1024")
    assert_equal 2252, get_diskspace_mb("2G:2.2G")
    assert_equal 1126, get_diskspace_mb("1048576:1153024")
    assert_equal 0, get_diskspace_mb(nil)
    assert_equal 0, get_diskspace_mb("0:unlimited")
  end

  test "ram limit conversion" do
    assert_equal 512, get_ram_mb("0:512M")
    assert_equal 2048, get_ram_mb("0:2G")
    assert_equal 1024, get_ram_mb("0:1048576k")
    assert_equal 10, get_ram_mb('2560P:2560P')
    assert_equal 100, get_ram_mb('0:104857600')
    assert_equal 100, get_ram_mb('0:104857600B')
    assert_equal 0, get_ram_mb(nil)
    assert_equal 0, get_ram_mb("0:unlimited")
  end
end

