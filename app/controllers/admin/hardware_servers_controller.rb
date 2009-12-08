class Admin::HardwareServersController < AdminController
  
  def list
    @up_level = '/admin/dashboard'
  end
  
  def list_data
    @hardware_servers = HardwareServer.all
    @hardware_servers.map! { |item| {
      :id => item.id,
      :host => item.host,
      :description => item.description
    }}
    render :json => { :data => @hardware_servers }  
  end
  
  def connect
    @hardware_server = HardwareServer.new(params)
    
    if @hardware_server.connect
      render :json => { :success => true }  
    else
      render :json => { :success => false, :errors => @hardware_server.errors }
    end
  end
  
  def disconnect
    params[:ids].split(',').each { |id|
      hardware_server = HardwareServer.find(id)  
      logger.info "Disconnecting hardware server with id: #{id}"
      
      if !hardware_server.disconnect
        render :json => { :success => false }  
        return
      end
    }
    
    render :json => { :success => true }  
  end
  
  def show
    @hardware_server = HardwareServer.find_by_id(params[:id])    
    redirect_to :action => 'list' if !@hardware_server
    @up_level = '/admin/hardware-servers/list'
  end
  
end
