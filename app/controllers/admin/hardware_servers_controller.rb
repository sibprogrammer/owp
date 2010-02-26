class Admin::HardwareServersController < AdminController
  before_filter :superadmin_required
  
  def list
    @up_level = '/admin/dashboard'
  end
  
  def list_data
    @hardware_servers = HardwareServer.all
    @hardware_servers.map! { |item| {
      :id => item.id,
      :host => item.host,
      :virtual_servers => item.virtual_servers.count,
      :description => item.description
    }}
    render :json => { :data => @hardware_servers }  
  end
  
  def save
    @hardware_server = (params[:id].to_i > 0) ? HardwareServer.find_by_id(params[:id]) : HardwareServer.new
    params.delete(:auth_key) if !@hardware_server.new_record? && params[:auth_key].empty?
    @hardware_server.attributes = params
    
    if @hardware_server.connect
      render :json => { :success => true }  
    else
      render :json => { :success => false, :form_errors => @hardware_server.errors }
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
    
    @os_templates = @hardware_server.os_templates.map { |item| {
      :id => item.id,
      :name => item.name,
    }}
    
    @virtual_servers_owners = User.get_virtual_servers_owners.map { |user| {
      :id => user.id,
      :login => user.login,
    }}
    @virtual_servers_owners << { :id => 0, :login => t('admin.virtual_servers.form.create_server.field.no_owner') }
    
    @up_level = '/admin/hardware-servers/list'
  end
  
  def sync
    params[:ids].split(',').each { |id|
      hardware_server = HardwareServer.find(id)
      
      if !hardware_server.sync
        render :json => { :success => false }  
        return
      end
    }
    
    render :json => { :success => true }  
  end
  
  def load_data
    hardware_server = HardwareServer.find_by_id(params[:id])
    redirect_to :action => 'list' if !hardware_server
    render :json => { :success => true, :data => {
      :host => hardware_server.host,
      :description => hardware_server.description
    }}  
  end
  
end
