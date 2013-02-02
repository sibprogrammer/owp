class Admin::ServerTemplatesController < Admin::Base
  before_filter :superadmin_required

  def list
    @hardware_server = HardwareServer.find_by_id(params[:hardware_server_id])
    redirect_to(:controller => 'hardware_servers', :action => 'list') and return if !@hardware_server
    @up_level = "/admin/hardware-servers/show?id=#{@hardware_server.id}"

    server_template = @hardware_server.server_templates.find_by_name(@hardware_server.default_server_template)
    server_template ||= @hardware_server.server_templates.first
    @advanced_limits = server_template.get_advanced_limits
    @server_templates_list = server_templates_list(@hardware_server)
  end

  def list_data
    hardware_server = HardwareServer.find_by_id(params[:hardware_server_id])
    render :json => { :data => server_templates_list(hardware_server) }
  end

  def delete
    objects_group_operation(ServerTemplate, :delete_physically)
  end

  def save
    hardware_server = HardwareServer.find_by_id(params[:hardware_server_id])
    redirect_to(:controller => 'hardware_servers', :action => 'list') and return if !hardware_server

    server_template = (params[:id].to_i > 0) ? ServerTemplate.find_by_id(params[:id]) : ServerTemplate.new
    params[:raw_limits] = ActiveSupport::JSON.decode(params[:raw_limits])
    server_template.attributes = params
    server_template.hardware_server = hardware_server

    if server_template.save_physically
      render :json => { :success => true }
    else
      render :json => { :success => false, :form_errors => server_template.errors }
    end
  end

  def load_data
    server_template = ServerTemplate.find_by_id(params[:id])
    redirect_to :controller => 'server_templates', :action => 'list' and return if !server_template

    render :json => { :success => true, :data => {
      :name => server_template.name,
      :nameserver => server_template.get_nameserver,
      :search_domain => server_template.get_search_domain,
      :start_on_boot => server_template.get_start_on_boot,
      :diskspace => server_template.get_diskspace,
      :memory => server_template.get_memory,
      :vswap => server_template.get_vswap,
      :cpu_units => server_template.get_cpu_units,
      :cpus => server_template.get_cpus,
      :cpu_limit => server_template.get_cpu_limit,
      :raw_limits => server_template.get_advanced_limits.to_json,
    }}
  end

  private

    def server_templates_list(hardware_server)
      server_templates = hardware_server.server_templates
      server_templates.map! do |item|
        {
          :id => item.id,
          :name => item.name,
          :is_default => item.name == hardware_server.default_server_template,
          :virtual_servers => VirtualServer.count(:conditions => ["hardware_server_id = ? AND orig_server_template = ?", hardware_server.id, item.name]),
        }
      end
    end

end
