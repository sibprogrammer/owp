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
  
  def available_list_data 
    os_templates = params[:contributed] ? OsTemplate.get_available_contributed : OsTemplate.get_available_official
    os_templates.map! { |item| {
      :name => item.sub(/\.tar\.gz$/, ''),
    }}
    render :json => { :data => os_templates }  
  end
  
  def install
    hardware_server = HardwareServer.find_by_id(params[:hardware_server_id])
    render(:json => { :success => false }) and return if !hardware_server
    
    jobs_ids = []
    
    params[:selected_official_templates].split(',').each { |name|
      jobs_ids.push(OsTemplate.install_official(hardware_server, name)['job_id'])
    }
    
    params[:selected_contributed_templates].split(',').each { |name|
      jobs_ids.push(OsTemplate.install_contributed(hardware_server, name)['job_id'])
    }
      
    spawn do
      while true
        jobs_running = false        
        jobs_ids.each { |job_id|
          jobs_running = true if hardware_server.rpc_client.job_status(job_id)['alive']          
        }        
        break unless jobs_running        
        sleep 10
      end
      
      hardware_server.sync_os_templates
      logger.debug "Installation of OS templates was finished."
    end
   
    render :json => { :success => true }  
  end
  
end
