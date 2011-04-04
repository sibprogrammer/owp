class Admin::IpAddressesController < Admin::Base
  before_filter :superadmin_required

  def list
    @up_level = '/admin/dashboard'
    @ip_addresses_list = VirtualServer.ip_addresses
    @ip_pools_list = ip_pools_list
    @hardware_servers = HardwareServer.all.map{ |server| { :id => server.id, :host => server.host, }}
    @hardware_servers << { :id => 0, :host => t('admin.ip_pools.form.create.field.all_servers') }
  end

  def list_data
    render :json => { :data => VirtualServer.ip_addresses }
  end

end
