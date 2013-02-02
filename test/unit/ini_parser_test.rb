require 'test_helper'

class IniParserTest < ActiveSupport::TestCase

  def setup
    config = <<-EOS
TEMPLATE=/var/lib/vz/template
VE_PRIVATE=/var/lib/vz/private/$VEID
CONFIGFILE="vps.basic"

# line with comments
NEIGHBOUR_DEVS = detect
VZFASTBOOT = "no"
  VE0CPUUNITS=1000
IPV6="no"
DISKSPACE="2G:2.2G"
DISKSPACE2="2048"
DISKSPACE3="1153024:1153024"
    EOS
    @parser = IniParser.new(config)
  end

  test "Read value by key" do
    assert_equal '/var/lib/vz/template', @parser.get('TEMPLATE')
    assert_equal '/var/lib/vz/private/$VEID', @parser.get('VE_PRIVATE')
    assert_equal 'vps.basic', @parser.get('CONFIGFILE')
    assert_equal 'detect', @parser.get('NEIGHBOUR_DEVS')
    assert_equal 'no', @parser.get('VZFASTBOOT')
    assert_equal 'no', @parser.get('IPV6')
    assert_equal 1000, @parser.get('VE0CPUUNITS').to_i
    assert_equal 2252, @parser.get_mb('DISKSPACE')
    assert_equal 2, @parser.get_mb('DISKSPACE2')
    assert_equal 1126, @parser.get_mb('DISKSPACE3')
  end

  test "Read non-existent key" do
    assert_nil @parser.get('NO_KEY')
  end

end
