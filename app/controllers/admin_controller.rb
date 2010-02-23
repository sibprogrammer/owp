class AdminController < ApplicationController
  layout 'admin'  
  before_filter :login_required, :servers_list
  
  private
  
  def servers_list
    if @current_user.superadmin?
      @servers_list = HardwareServer.all
      @servers_list.map! { |server| {
        :cls => 'menu-item',
        :text => server.host,
        :href => '/admin/hardware-servers/show?id=' + server.id.to_s,
        :icon => '/images/server.png',
        :leaf => true
      }}
    else
      @servers_list = @current_user.virtual_servers
      @servers_list = @servers_list.map { |server| {
        :cls => 'menu-item',
        :text => ('#' + server.identity.to_s) + (server.host_name.blank? ? '' : (' - ' + server.host_name)),
        :href => '/admin/virtual-servers/show?id=' + server.id.to_s,
        :icon => '/images/server.png',
        :leaf => true
      }}
    end
  end
  
end
