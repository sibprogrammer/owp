class Admin::VirtualServersController < AdminController
  before_filter :superadmin_required, :only => [:list_data, :delete, :create, :load_data]
  
  def list
    @up_level = '/admin/dashboard'
  end
  
  def owner_list_data
    render :json => { :data => get_virtual_servers_map(@current_user.virtual_servers) }
  end
  
  def list_data
    hardware_server = HardwareServer.find_by_id(params[:hardware_server_id])
    virtual_servers = hardware_server.virtual_servers
    render :json => { :data => get_virtual_servers_map(virtual_servers) }
  end
  
  def change_state
    params[:ids].split(',').each { |id|
      virtual_server = VirtualServer.find_by_id(id)
      next if !@current_user.can_control(virtual_server)
      
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
      :orig_os_template => virtual_server.orig_os_template,
      :orig_server_template => virtual_server.orig_server_template,
      :ip_address => virtual_server.ip_address,
      :host_name => virtual_server.host_name,
      :start_on_boot => virtual_server.start_on_boot,
      :nameserver => virtual_server.nameserver,
      :search_domain => virtual_server.search_domain,
      :diskspace => virtual_server.diskspace,
      :memory => virtual_server.memory,
      :user_id => virtual_server.user_id,
    }}  
  end
  
  def show
    @virtual_server = VirtualServer.find_by_id(params[:id])
    redirect_to :controller => 'dashboard' and return if !@virtual_server or !@current_user.can_control(@virtual_server)
    
    if @current_user.superadmin?
      @up_level = '/admin/hardware-servers/show?id=' + @virtual_server.hardware_server.id.to_s
    else
      @up_level = '/admin/virtual-servers/list'
    end
  end
  
  def get_properties
    virtual_server = VirtualServer.find_by_id(params[:id])
    redirect_to :controller => 'dashboard' and return if !virtual_server or !@current_user.can_control(virtual_server)

    render :json => { :success => true, :data => [
      {
        :parameter => t('admin.virtual_servers.form.create_server.field.identity'),
        :value => virtual_server.identity,
      }, {
        :parameter => t('admin.virtual_servers.form.create_server.field.status'),
        :value => '<img src="/images/' + (('running' == virtual_server.state) ? 'run' : 'stop') + '.png"/>',
      }, {
        :parameter => t('admin.virtual_servers.form.create_server.field.os_template'),
        :value => virtual_server.orig_os_template,
      }, {
        :parameter => t('admin.virtual_servers.form.create_server.field.server_template'),
        :value => virtual_server.orig_server_template,
      }, {
        :parameter => t('admin.virtual_servers.form.create_server.field.ip_address'),
        :value => virtual_server.ip_address,
      }, {
        :parameter => t('admin.virtual_servers.form.create_server.field.host_name'),
        :value => virtual_server.host_name,
      }, {
        :parameter => t('admin.virtual_servers.form.create_server.field.diskspace'),
        :value => virtual_server.diskspace,
      }, {
        :parameter => t('admin.virtual_servers.form.create_server.field.memory'),
        :value => virtual_server.memory,
      }, {
        :parameter => t('admin.virtual_servers.form.create_server.field.nameserver'),
        :value => virtual_server.nameserver,
      }, {
        :parameter => t('admin.virtual_servers.form.create_server.field.searchdomain'),
        :value => virtual_server.search_domain,
      }
    ]}
  end
  
  def get_limits
    virtual_server = VirtualServer.find_by_id(params[:id])
    redirect_to :controller => 'dashboard' and return if !virtual_server or !@current_user.can_control(virtual_server)
    
    render :json => { :success => true, :data => virtual_server.get_limits }
  end
  
  def save_limits
    virtual_server = VirtualServer.find_by_id(params[:id])
    redirect_to :controller => 'dashboard' and return if !virtual_server or !@current_user.superadmin?
    
    virtual_server.save_limits(ActiveSupport::JSON.decode(params[:limits]))
    
    render :json => { :success => true }
  end
  
  def load_template
    server_template = ServerTemplate.find_by_id(params[:id])
    redirect_to :controller => 'hardware_servers', :action => 'list' and return if !server_template
    
    render :json => { :success => true, :data => {
      :start_on_boot => server_template.get_start_on_boot,
      :nameserver => server_template.get_nameserver,
      :search_domain => server_template.get_search_domain,
      :diskspace => server_template.get_diskspace,
      :memory => server_template.get_memory,
    }}
  end
  
  private 
  
  def get_virtual_servers_map(virtual_servers)
    virtual_servers = virtual_servers.map { |virtual_server| {
      :id => virtual_server.id,
      :identity => virtual_server.identity,
      :ip_address => virtual_server.ip_address.blank? ? '' : virtual_server.ip_address.split.join(', '),
      :host_name => virtual_server.host_name,
      :state => virtual_server.state,
      :os_template_name => virtual_server.orig_os_template,
      :diskspace => virtual_server.diskspace,
      :memory => virtual_server.memory,
      :owner => virtual_server.user ? virtual_server.user.login : '',
    }} 
  end
  
end
