class Iphone::OsTemplatesController < Iphone::Base
  before_filter :superadmin_required

  def list
    @page_title = t('admin.hardware_servers.top_toolbar.os_templates')

    hardware_server = HardwareServer.find_by_id(params[:hardware_server_id])
    redirect_to(:controller => 'hardware_servers', :action => 'list') and return if !hardware_server

    @os_templates = hardware_server.os_templates
    @os_templates.map! do |item|
      {
        :id => item.id,
        :name => item.name,
        :virtual_servers => VirtualServer.count(:conditions => ["hardware_server_id = ? AND orig_os_template = ?", hardware_server.id, item.name]),
      }
    end
  end

end
