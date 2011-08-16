require 'test_helper'

class HardwareServerTest < ActiveSupport::TestCase

  test "Disconnect physical server" do
    assert_not_nil HardwareServer.find_by_host('rock.lan')
    server = hardware_servers(:rock)
    server.disconnect
    assert_nil HardwareServer.find_by_host('rock.lan')
  end

end
