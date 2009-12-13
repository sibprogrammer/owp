class Admin::OsTemplatesController < AdminController
  
  def list
    @hardware_server = HardwareServer.find_by_id(params[:hardware_server_id])    
    redirect_to(:controller => 'hardware_servers', :action => 'list') and return if !@hardware_server
    @up_level = "/admin/hardware-servers/show?id=#{@hardware_server.id}"
  end
  
  def list_data
    hardware_server = HardwareServer.find_by_id(params[:hardware_server_id])
    os_templates = hardware_server.os_templates
    os_templates.map! { |item| {
      :id => item.id,
      :name => item.name,
    }}
    render :json => { :data => os_templates }  
  end
  
end
