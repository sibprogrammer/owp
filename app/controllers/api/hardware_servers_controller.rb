class Api::HardwareServersController < Api::Base
  before_filter :superadmin_required, :set_hidden_attrs
  before_filter :set_server_by_id, :only => [ :get, :update, :disconnect, :sync, :virtual_servers, :os_templates, :server_templates ]

  def list
    hardware_servers = HardwareServer.all
    render_object_result(hardware_servers, :root => 'hardware_servers', :except => @hidden_attrs)
  end

  def get
    render_object_result(@hardware_server, :except => @hidden_attrs)
  end

  def get_by_host
    hardware_server = HardwareServer.find_by_host(params[:host])
    render_error :reason => 'object_not_found' if !hardware_server
    render_object_result(hardware_server, :except => @hidden_attrs) if hardware_server
  end

  def connect
    create_or_update_server
  end

  def update
    create_or_update_server
  end

  def disconnect
    render_scalar_result(@hardware_server.disconnect)
  end

  def sync
    render_scalar_result(@hardware_server.sync)
  end

  def virtual_servers
    render_object_result(@hardware_server.virtual_servers, :root => 'virtual_servers')
  end

  def os_templates
    render_object_result(@hardware_server.os_templates, :root => 'os_templates', :except => 'hardware_server_id')
  end

  def server_templates
    render_object_result(@hardware_server.server_templates, :root => 'server_templates', :except => 'hardware_server_id')
  end

  private

    def set_hidden_attrs
      @hidden_attrs = [ :auth_key, :backups_dir, :ve_private, :vzctl_version, :templates_dir ]
    end

    def set_server_by_id
      @hardware_server = HardwareServer.find_by_id(params[:id])
      render_error :reason => 'object_not_found' if !@hardware_server
    end

    def create_or_update_server
      @hardware_server = HardwareServer.new unless @hardware_server
      @hardware_server.attributes = params
      render_object_save_result(@hardware_server.connect(params[:root_password]), @hardware_server)
    end

end
