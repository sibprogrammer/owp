class Admin::ServerTemplatesController < Admin::Base
  before_filter :superadmin_required
  
  def list
    @hardware_server = HardwareServer.find_by_id(params[:hardware_server_id])
    redirect_to(:controller => 'hardware_servers', :action => 'list') and return if !@hardware_server
    @up_level = "/admin/hardware-servers/show?id=#{@hardware_server.id}"
    
    server_template = ServerTemplate.find_by_name(@hardware_server.default_server_template)
    @advanced_limits = server_template.get_advanced_limits
  end
  
  def list_data
    hardware_server = HardwareServer.find_by_id(params[:hardware_server_id])
    server_templates = hardware_server.server_templates
    server_templates.map! { |item| {
      :id => item.id,
      :name => item.name,
      :is_default => item.name == hardware_server.default_server_template
    }}
    render :json => { :data => server_templates }
  end
  
  def delete
    params[:ids].split(',').each { |id|
      server_template = ServerTemplate.find(id) 
      
      if !server_template.delete_physically
        render :json => { :success => false }
        return
      end
    }
    
    render :json => { :success => true }
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
      :cpu_units => server_template.get_cpu_units,
      :cpus => server_template.get_cpus,
      :cpu_limit => server_template.get_cpu_limit,
      :raw_limits => server_template.get_advanced_limits.to_json,
    }}
  end
  
end
