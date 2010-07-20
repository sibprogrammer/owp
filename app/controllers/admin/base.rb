class Admin::Base < ApplicationController
  layout 'admin'  
  before_filter :login_required, :servers_list
  
  protected
  
    def superadmin_required
      redirect_to :controller => 'admin/dashboard' if !@current_user.superadmin?
    end
  
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
        :description => virtual_server.description.to_s,
      }} 
    end
    
end
