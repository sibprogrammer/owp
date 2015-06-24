class Api::VirtualServersController < Api::Base
  before_filter :superadmin_required, :only => [ :delete, :create, :update, :get_by_host ]
  before_filter :set_server_by_id, :only => [ :get, :get_advanced_limits, :delete, :start, :stop, :restart, :update,
    :get_stats, :reinstall, :exec ]

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

  def get_stats
    render_object_result get_usage_stats(@virtual_server)
  end

  def reinstall
    @virtual_server.password = params[:password]
    @virtual_server.orig_os_template = params[:orig_os_template] if @current_user.can_select_os_on_reinstall?

    unless @virtual_server.valid?
      render_error :reason => 'object_not_valid'
    end

    unless @virtual_server.reinstall && @virtual_server.save_physically
      render_error :reason => 'error_occured'
    end

    render_object_result({ :success => true })
  end

  def exec
    render_scalar_result(@virtual_server.run_command(params[:command]))
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

  def get_usage_stats(virtual_server)
    is_running = 'running' == virtual_server.real_state

    stats = []

    counter = Watchdog.get_ve_counter('_cpu_usage', virtual_server.id)

    if counter and is_running
      stats << {
          :parameter => "cpu_load_average",
          :value => {
              'text' => "#{counter.held}%",
              'percent' => counter.held.to_f / 100,
          }
      }
    else
      stats << { :parameter => 'cpu_load_average', :value => '-' }
    end

    helper = Object.new.extend(ActionView::Helpers::NumberHelper)

    counter = Watchdog.get_ve_counter('_diskspace', virtual_server.id)

    if counter and is_running and (counter.limit.to_i > 0)
      stats << {
          :parameter => 'disk_space',
          :value => {
              'text' => t(
                  'admin.virtual_servers.stats.value.disk_usage',
                  :percent => (counter.held.to_f / counter.limit.to_f * 100).to_i.to_s,
                  :free =>  helper.number_to_human_size(counter.limit.to_i - counter.held.to_i, :locale => :en),
                  :used => helper.number_to_human_size(counter.held.to_i, :locale => :en),
                  :total => helper.number_to_human_size(counter.limit.to_i, :locale => :en)
              ),
              'percent' => counter.held.to_f / counter.limit.to_f
          }
      }
    else
      stats << { :parameter => "disk_space", :value => '-' }
    end

    counter = Watchdog.get_ve_counter('_memory', virtual_server.id)

    if counter and is_running and (counter.limit.to_i > 0)
      stats << {
          :parameter => 'memory',
          :value => {
              'text' => t(
                  'admin.virtual_servers.stats.value.memory_usage',
                  :percent => (counter.held.to_f / counter.limit.to_f * 100).to_i.to_s,
                  :free =>  helper.number_to_human_size(counter.limit.to_i - counter.held.to_i, :locale => :en),
                  :used => helper.number_to_human_size(counter.held.to_i, :locale => :en),
                  :total => helper.number_to_human_size(counter.limit.to_i, :locale => :en)
              ),
              'percent' => counter.held.to_f / counter.limit.to_f
          }
      }
    else
      stats << { :parameter => "memory", :value => '-' }
    end
    stats
  end
end
