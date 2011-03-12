class Admin::IpAddressesController < Admin::Base
  before_filter :superadmin_required

  def list
    @up_level = '/admin/dashboard'
    @ip_addresses_list = VirtualServer.ip_addresses
  end

  def list_data
    render :json => { :data => VirtualServer.ip_addresses }
  end

end
