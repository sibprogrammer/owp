class Api::VirtualServersController < Api::Base
  before_filter :superadmin_required, :only => [ :delete, :create, :update ]
  before_filter :set_server_by_id, :only => [ :get, :get_advanced_limits, :delete, :start, :stop, :restart, :update ]

  def own_servers
    virtual_servers = @current_user.virtual_servers
    render_object_result(virtual_servers, :root => 'virtual_servers')
  end

  def get
    render_object_result(@virtual_server)
  end

  def get_advanced_limits
    render_object_result(@virtual_server.get_limits, :root => 'limits')
  end

  def delete
    render_scalar_result(@virtual_server.delete_physically)
  end

  def start
    render_scalar_result(@virtual_server.start)
  end

  def stop
    render_scalar_result(@virtual_server.stop)
  end

  def restart
    render_scalar_result(@virtual_server.restart)
  end

  def create
    create_or_update_server
  end

  def update
    create_or_update_server
  end

  private

    def set_server_by_id
      @virtual_server = VirtualServer.find_by_id(params[:id])
      redirect_to :controller => 'error', :reason => 'object_not_found' if !@virtual_server or !@current_user.can_control(@virtual_server)
    end

    def create_or_update_server
      @virtual_server = VirtualServer.new unless @virtual_server
      @virtual_server.attributes = params
      render_object_save_result(@virtual_server.save_physically, @virtual_server)
    end

end
