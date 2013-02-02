class Admin::SearchController < Admin::Base
  before_filter :superadmin_required

  def index
    search_fields = [ "identity", "description", "host_name", "ip_address", "orig_os_template", "orig_server_template" ]
    virtual_servers = VirtualServer.find(:all, :conditions => [
      search_fields.map{ |item| item + " LIKE :query" }.join(' OR '), { :query => "%" + params[:query] + "%" }
    ])

    result = []

    virtual_servers.each do |virtual_server|
      description =
        "<a href='#{base_url}/admin/virtual-servers/show?id=#{virtual_server.id}'>" +
        t("admin.virtual_servers.show.title", :name => "#" + virtual_server.identity.to_s) +
        "</a><br/>" +
        (virtual_server.description.blank? ? '' : virtual_server.description + "<br>") +
        [
          virtual_server.host_name,
          virtual_server.ip_address,
          virtual_server.orig_os_template,
          virtual_server.orig_server_template,
          virtual_server.hardware_server.host
        ].reject(&:blank?).join(', ')
      result << { :item => description }
    end

    render :json => { :data => result }
  end

end
