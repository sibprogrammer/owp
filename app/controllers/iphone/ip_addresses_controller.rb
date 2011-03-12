class Iphone::IpAddressesController < Iphone::Base
  before_filter :superadmin_required

  def list
    @page_title = t('admin.ip_addresses.title')
    @ip_addresses_list = VirtualServer.ip_addresses.sort { |a,b| a[:name] <=> b[:name] }
  end

end
