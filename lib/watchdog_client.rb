class WatchdogClient

  SERVER_URI = "druby://localhost:7787"

  def initialize
    DRb.start_service('druby://localhost:0')
    @server = DRbObject.new_with_uri(SERVER_URI)
  end

  def alive
    begin
      return @server.alive
    rescue
      false
    end
  end

  def get_ve_counter(name, server_id)
    begin
      return @server.get_ve_counter(name, server_id)
    rescue
      false
    end
  end

  def remove_ve_counter(name, server_id)
    begin
      return @server.remove_ve_counter(name, server_id)
    rescue
      false
    end
  end

  def get_ve_counters_queue(name, server_id)
    begin
      return @server.get_ve_counters_queue(name, server_id)
    rescue
      []
    end
  end

  def get_hw_param(name, server_id)
    begin
      return @server.get_hw_param(name, server_id)
    rescue
      nil
    end
  end

end
