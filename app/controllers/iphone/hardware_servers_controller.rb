class Iphone::HardwareServersController < Iphone::Base
  before_filter :superadmin_required

  def list
    @page_title = t('admin.hardware_servers.title')
  end

  def show
    @hardware_server = HardwareServer.find_by_id(params[:id])
    redirect_to :action => 'list' if !@hardware_server and return

    @page_title = @hardware_server.host

    @virtual_servers = @hardware_server.virtual_servers
    @virtual_servers.map! do |virtual_server|
      {
        :id => virtual_server.id,
        :identity => virtual_server.identity,
        :ip_address => virtual_server.ip_address.blank? ? '' : virtual_server.ip_address.split.join(', '),
        :host_name => virtual_server.host_name,
        :description => virtual_server.description,
      }
    end
  end

end
