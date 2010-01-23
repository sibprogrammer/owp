class Admin::VirtualServersController < AdminController
  
  def list_data
    hardware_server = HardwareServer.find_by_id(params[:hardware_server_id])
    virtual_servers = hardware_server.virtual_servers
    virtual_servers.map! { |virtual_server| {
      :id => virtual_server.id,
      :identity => virtual_server.identity,
      :ip_address => virtual_server.ip_address,
      :host_name => virtual_server.host_name,
      :state => virtual_server.state,
      :os_template_name => virtual_server.os_template ? virtual_server.os_template.name : '-',
      :diskspace => virtual_server.diskspace,
      :memory => virtual_server.memory,
    }}
    render :json => { :data => virtual_servers }  
  end
  
  def change_state    
    params[:ids].split(',').each { |id|
      virtual_server = VirtualServer.find_by_id(id)
      
      case params[:command]  
        when 'start' then virtual_server.start
        when 'stop' then virtual_server.stop
        when 'restart' then virtual_server.restart
      end
    }
    
    render :json => { :success => true }  
  end
  
  def delete
    params[:ids].split(',').each { |id|
      virtual_server = VirtualServer.find(id) 
      
      if !virtual_server.delete_physically
        render :json => { :success => false }  
        return
      end
    }
    
    render :json => { :success => true }
  end
  
  def create
    hardware_server = HardwareServer.find_by_id(params[:hardware_server_id])    
    redirect_to :controller => 'hardware_servers', :action => 'list' if !hardware_server
    
    virtual_server = (params[:id].to_i > 0) ? VirtualServer.find_by_id(params[:id]) : VirtualServer.new
    if !virtual_server.new_record?
      params.delete(:identity)
      params.delete(:start_after_creation)
    end
    virtual_server.attributes = params
    virtual_server.start_on_boot = params.key?(:start_on_boot)
    
    if virtual_server.save_physically
      render :json => { :success => true }  
    else
      render :json => { :success => false, :form_errors => virtual_server.errors }
    end    
  end
  
  def load_data
    hardware_server = HardwareServer.find_by_id(params[:hardware_server_id])
    virtual_server = VirtualServer.find_by_id(params[:id])
    redirect_to :controller => 'hardware_servers', :action => 'list' if !hardware_server || !virtual_server
    
    render :json => { :success => true, :data => {
      :identity => virtual_server.identity,
      :os_template_id => virtual_server.os_template ? virtual_server.os_template.name : '-',
      :ip_address => virtual_server.ip_address,
      :host_name => virtual_server.host_name,
      :start_on_boot => virtual_server.start_on_boot,
      :nameserver => virtual_server.nameserver,
      :search_domain => virtual_server.search_domain,
      :diskspace => virtual_server.diskspace,
      :memory => virtual_server.memory,
    }}  
  end
  
end
