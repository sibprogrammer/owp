class Iphone::VirtualServersController < Iphone::Base

  def list
    @page_title = t('admin.virtual_servers.title')

    @virtual_servers = @current_user.virtual_servers
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

  def show
    @virtual_server = VirtualServer.find_by_id(params[:id])
    redirect_to :controller => 'dashboard' and return if !@virtual_server or !@current_user.can_control(@virtual_server)

    @page_title = "##{@virtual_server.identity}"
  end

end
