class Admin::OsTemplatesController < Admin::Base

  def list
    @hardware_server = HardwareServer.find_by_id(params[:hardware_server_id])
    redirect_to(:controller => 'hardware_servers', :action => 'list') and return if !@hardware_server
    @up_level = "/admin/hardware-servers/show?id=#{@hardware_server.id}"
    @os_templates_list = os_templates_list(@hardware_server)
  end

  def list_data
    hardware_server = HardwareServer.find_by_id(params[:hardware_server_id])
    render :json => { :data => os_templates_list(hardware_server) }
  end

  def available_list_data
    hardware_server = HardwareServer.find_by_id(params[:hardware_server_id])
    installed_templates = hardware_server.os_templates.map { |item| item.name }

    os_templates = params[:contributed] ? OsTemplate.get_available_contributed : OsTemplate.get_available_official
    os_templates.map! do |file|
      template_name = file['name'].sub(/\.tar\.gz$/, '')
      if installed_templates.include?(template_name)
        nil
      else
        { :name => template_name, :size => file['size'].to_i / (1024 * 1024) }
      end
    end.compact!

    render :json => { :data => os_templates }
  end

  def install
    hardware_server = HardwareServer.find_by_id(params[:hardware_server_id])
    render(:json => { :success => false }) and return if !hardware_server

    jobs_ids = []

    params[:selected_official_templates].split(',').each do |name|
      jobs_ids.push(OsTemplate.install_official(hardware_server, name)['job_id'])
    end

    params[:selected_contributed_templates].split(',').each do |name|
      jobs_ids.push(OsTemplate.install_contributed(hardware_server, name)['job_id'])
    end

    jobs_ids.push(OsTemplate.install_from_url(hardware_server, params[:template_url])['job_id']) unless params[:template_url].blank?

    spawn do
      job = BackgroundJob.create('os_templates.install', { :host => hardware_server.host })

      while true
        jobs_running = false
        jobs_ids.each{ |job_id| jobs_running = true if hardware_server.rpc_client.job_status(job_id)['alive'] }
        break unless jobs_running
        sleep 10
      end

      job.finish
      hardware_server.sync_os_templates
      logger.debug "Installation of OS templates was finished."
    end

    render :json => { :success => true }
  end

  def delete
    objects_group_operation(OsTemplate, :delete_physically)
  end

  private

    def os_templates_list(hardware_server)
      os_templates = hardware_server.os_templates
      os_templates.map! do |item|
        {
          :id => item.id,
          :name => item.name,
          :size => item.size,
          :virtual_servers => VirtualServer.count(:conditions => ["hardware_server_id = ? AND orig_os_template = ?", hardware_server.id, item.name]),
        }
      end
    end

end
