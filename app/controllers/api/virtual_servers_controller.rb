class Api::VirtualServersController < Api::Base
  before_filter :superadmin_required, :only => [ :delete, :create, :update, :get_by_host ]
  before_filter :set_server_by_id, :only => [ :get, :get_advanced_limits, :delete, :start, :stop, :restart, :update ]

  def own_servers
    virtual_servers = @current_user.virtual_servers
    render_object_result(virtual_servers, :root => 'virtual_servers')
  end

  def get
    render_object_result(@virtual_server)
  end

  def get_by_host
    virtual_server = VirtualServer.find_by_host_name(params[:host])
    render_error :reason => 'object_not_found' if !virtual_server
    render_object_result(virtual_server) if virtual_server
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
      render_error :reason => 'object_not_found' if !@virtual_server or !@current_user.can_control(@virtual_server)
    end

    def create_or_update_server
      if !@virtual_server
        template_params = {}
        server_template = ServerTemplate.find_by_name(params[:orig_server_template])

        if server_template
          template_params = {
            :nameserver => server_template.get_nameserver,
            :search_domain => server_template.get_search_domain,
            :start_on_boot => server_template.get_start_on_boot,
            :diskspace => server_template.get_diskspace,
            :memory => server_template.get_memory,
            :vswap => server_template.get_vswap,
            :cpu_units => server_template.get_cpu_units,
            :cpus => server_template.get_cpus,
            :cpu_limit => server_template.get_cpu_limit,
          }
        end

        @virtual_server = VirtualServer.new(template_params)
      end

      @virtual_server.attributes = params
      render_object_save_result(@virtual_server.save_physically, @virtual_server)
    end

end
