class Admin::ServerTemplatesController < AdminController
  before_filter :superadmin_required
  
  def list
    @hardware_server = HardwareServer.find_by_id(params[:hardware_server_id])
    redirect_to(:controller => 'hardware_servers', :action => 'list') and return if !@hardware_server
    @up_level = "/admin/hardware-servers/show?id=#{@hardware_server.id}"
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
  
end
