class Iphone::ServerTemplatesController < Iphone::Base
  before_filter :superadmin_required

  def list
    @page_title = t('admin.hardware_servers.top_toolbar.server_templates')

    hardware_server = HardwareServer.find_by_id(params[:hardware_server_id])
    redirect_to(:controller => 'hardware_servers', :action => 'list') and return if !hardware_server

    @server_templates = hardware_server.server_templates
    @server_templates.map! do |item|
      {
        :id => item.id,
        :name => item.name,
        :is_default => item.name == hardware_server.default_server_template,
        :virtual_servers => VirtualServer.count(:conditions => ["hardware_server_id = ? AND orig_server_template = ?", hardware_server.id, item.name]),
      }
    end
  end

end
