class Admin::VirtualServersController < Admin::Base
  before_filter :superadmin_required, :only => [:list_data, :delete, :create, :clone]
  
  def list
    @up_level = '/admin/dashboard'
    @virtual_servers_list = get_virtual_servers_map(@current_user.virtual_servers)
  end
  
  def owner_list_data
    render :json => { :data => get_virtual_servers_map(@current_user.virtual_servers) }
  end
  
  def list_data
    hardware_server = HardwareServer.find_by_id(params[:hardware_server_id])
    render :json => { :data => get_virtual_servers_map(hardware_server.virtual_servers) }
  end
  
  def change_state
    params[:ids].split(',').each { |id|
      virtual_server = VirtualServer.find_by_id(id)
      next if !@current_user.can_control(virtual_server)
      
      case params[:command]  
        when 'start' then result = virtual_server.start
        when 'stop' then result = virtual_server.stop
        when 'restart' then result = virtual_server.restart
      end
      
      render :json => { :success => false } and return if !result
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
    virtual_server = VirtualServer.find_by_id(params[:id])
    redirect_to :controller => 'dashboard' and return if !virtual_server or !@current_user.can_control(virtual_server)
    
    render :json => { :success => true, :data => {
      :identity => virtual_server.identity,
      :orig_os_template => virtual_server.orig_os_template,
      :orig_server_template => virtual_server.orig_server_template,
      :ip_address => virtual_server.ip_address,
      :host_name => virtual_server.host_name,
      :start_on_boot => virtual_server.start_on_boot,
      :nameserver => virtual_server.nameserver,
      :search_domain => virtual_server.search_domain,
      :diskspace => 0 == virtual_server.diskspace ? '' : virtual_server.diskspace,
      :memory => 0 == virtual_server.memory ? '' : virtual_server.memory,
      :cpu_units => virtual_server.cpu_units,
      :cpus => virtual_server.cpus,
      :cpu_limit => virtual_server.cpu_limit,
      :expiration_date => virtual_server.expiration_date.blank? ? '' : virtual_server.expiration_date.strftime("%Y.%m.%d"),
      :user_id => virtual_server.user_id,
      :description => virtual_server.description,
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
    
    @virtual_server_properties = virtual_server_properties(@virtual_server)
  end
  
  def get_properties
    virtual_server = VirtualServer.find_by_id(params[:id])
    redirect_to :controller => 'dashboard' and return if !virtual_server or !@current_user.can_control(virtual_server)

    render :json => { :success => true, :data => virtual_server_properties(virtual_server) }
  end
  
  def get_stats
    virtual_server = VirtualServer.find_by_id(params[:id])
    redirect_to :controller => 'dashboard' and return if !virtual_server or !@current_user.can_control(virtual_server)

    stats = []
    
    if 'running' == virtual_server.state
      stats << {
        :parameter => t('admin.virtual_servers.stats.field.cpu_load_average'),
        :value => virtual_server.cpu_load_average.join(', '),
      }
    end
    
    helper = Object.new.extend(ActionView::Helpers::NumberHelper)
    
    disk_usage = virtual_server.disk_usage
    
    stats << {
      :parameter => t('admin.virtual_servers.stats.field.disk_usage'),
      :value => {
        'text' => t(
          'admin.virtual_servers.stats.value.disk_usage',
          :percent => disk_usage['usage_percent'].to_s,
          :free =>  helper.number_to_human_size(disk_usage['free_bytes'], :locale => :en),
          :used => helper.number_to_human_size(disk_usage['used_bytes'], :locale => :en),
          :total => helper.number_to_human_size(disk_usage['total_bytes'], :locale => :en)
        ),
        'percent' => disk_usage['usage_percent'].to_f / 100
      }
    }
    
    if 'running' == virtual_server.state
      memory_usage = virtual_server.memory_usage
      
      stats << {
        :parameter => t('admin.virtual_servers.stats.field.memory_usage'),
        :value => { 
          'text' => t(
            'admin.virtual_servers.stats.value.memory_usage',
            :percent => memory_usage['usage_percent'].to_s,
            :free =>  helper.number_to_human_size(memory_usage['free_bytes'], :locale => :en),
            :used => helper.number_to_human_size(memory_usage['used_bytes'], :locale => :en),
            :total => helper.number_to_human_size(memory_usage['total_bytes'], :locale => :en)
          ),
          'percent' => memory_usage['usage_percent'].to_f / 100
        }
      }
    end

    render :json => { :success => true, :data => stats }
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
      :cpu_units => server_template.get_cpu_units,
      :cpus => server_template.get_cpus,
      :cpu_limit => server_template.get_cpu_limit,
      :memory => server_template.get_memory,
    }}
  end
  
  def reinstall
    virtual_server = VirtualServer.find_by_id(params[:id])
    if !virtual_server or !@current_user.can_control(virtual_server) or !@current_user.can_reinstall_ve?
      redirect_to :controller => 'dashboard' and return
    end
    
    virtual_server.password = params[:password]
    virtual_server.password_confirmation = params[:password_confirmation]
    virtual_server.orig_os_template = params[:orig_os_template] if @current_user.superadmin?
    
    if !virtual_server.valid?
      render :json => { :success => false, :form_errors => virtual_server.errors } and return
    end
    
    if !virtual_server.reinstall || !virtual_server.save_physically
      render :json => { :success => false } and return
    end

    render :json => { :success => true }
  end
  
  def change_settings
    virtual_server = VirtualServer.find_by_id(params[:id])
    redirect_to :controller => 'dashboard' and return if !virtual_server or !@current_user.can_control(virtual_server)

    if !params[:password].blank?
      virtual_server.password = params[:password]
      virtual_server.password_confirmation = params[:password_confirmation]
    end
    virtual_server.host_name = params[:host_name]
    virtual_server.nameserver = params[:nameserver]
    virtual_server.search_domain = params[:search_domain]
    
    if virtual_server.save_physically
      render :json => { :success => true }  
    else
      render :json => { :success => false, :form_errors => virtual_server.errors }
    end
  end
  
  def run_command
    virtual_server = VirtualServer.find_by_id(params[:id])
    if !virtual_server or !@current_user.can_control(virtual_server) or !@current_user.can_use_ve_console?
      redirect_to :controller => 'dashboard' and return
    end
    result = virtual_server.run_command(params[:command])
    if result.key?('error')
      output =  I18n.t('admin.virtual_servers.form.console.error.code') + ' ' + result['error'].code.to_s + "\n" +
        I18n.t('admin.virtual_servers.form.console.error.output') + "\n" + result['error'].output
    else
      output = result['output']
    end
    render :json => { :success => true, :output => output }
  end
  
  def clone
    virtual_server = VirtualServer.find_by_id(params[:id])
    redirect_to :controller => 'dashboard' and return if !virtual_server or !@current_user.can_control(virtual_server)
    
    new_server = virtual_server.clone
    new_server.attributes = params
    
    if new_server.clone_physically(virtual_server)
      render :json => { :success => true }  
    else
      render :json => { :success => false, :form_errors => new_server.errors }
    end
  end
  
  private
  
    def virtual_server_properties(virtual_server)
      params = [
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
        }
      ]
      
      limits = %w{ ip_address host_name diskspace memory cpu_units cpus cpu_limit nameserver search_domain description }
      
      limits.each do |limit|
        if !virtual_server.send(limit).blank?
          case limit
            when 'diskspace' then value = virtual_server.human_diskspace
            when 'memory' then value = virtual_server.human_memory
            else value = virtual_server.send(limit)
          end
          params << {
            :parameter => t("admin.virtual_servers.form.create_server.field.#{limit}"),
            :value => value,
          }
        end
      end
      
      if !virtual_server.expiration_date.blank?
        is_expired = Date.today > virtual_server.expiration_date
        expiration_date = virtual_server.expiration_date.strftime("%Y.%m.%d")
        
        params << {
          :parameter => t('admin.virtual_servers.form.create_server.field.expiration_date'),
          :value => is_expired ? "<span class='error-text'>#{expiration_date}</span>" : expiration_date,
        }
      end
      
      params
    end
  
end
