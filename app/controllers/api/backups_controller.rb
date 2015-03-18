class Api::BackupsController < Api::Base
  before_filter :is_allowed
  before_filter :set_server_by_id, :only => [ :list, :list_data, :create ]
  before_filter :set_backup_by_id, :only => [ :restore, :delete ]


  def list
    render_object_result(backups_list(@virtual_server))
  end

  def list_data
    render_object_result(backups_list(@virtual_server))
  end

  def delete
    @backup.delete_physically
    render_object_result({ :success => true })
  end

  def create
    hardware_server = @virtual_server.hardware_server
    render_error :reason => 'backups.limit_reached' if @current_user.limit_reached?(:limit_backups, @virtual_server.backups.count)

    orig_ve_state = @virtual_server.state
    ve_state = params[:ve_state]

    if 'running' == orig_ve_state
      case ve_state
        when 'suspend' then @virtual_server.suspend
        when 'stop' then @virtual_server.stop
      end
    end

    result = @virtual_server.backup
    job_id = result[:job]['job_id']
    backup = result[:backup]
    backup.description = params[:description]

    spawn do
      job = BackgroundJob.create('backups.create', { :identity => @virtual_server.identity, :host => hardware_server.host })

      while true
        job_running = false
        job_running = true if hardware_server.rpc_client.job_status(job_id)['alive']
        break unless job_running
        sleep 10
      end

      job.finish
      backup.sync_size
      backup.save

      if 'running' == orig_ve_state
        case ve_state
          when 'suspend' then @virtual_server.resume
          when 'stop' then @virtual_server.start
        end
      end
    end

    render_object_result({ :success => true })
  end

  def restore
    orig_ve_state = @virtual_server.state
    @virtual_server.stop if 'running' == orig_ve_state

    job_id = @backup.restore['job_id']

    spawn do
      job = BackgroundJob.create('backups.restore', { :identity => @virtual_server.identity, :host => @virtual_server.hardware_server.host })

      while true
        job_running = false
        job_running = true if @virtual_server.hardware_server.rpc_client.job_status(job_id)['alive']
        break unless job_running
        sleep 10
      end

      job.finish
      @virtual_server.start if 'running' == orig_ve_state
    end
    render_object_result({ :success => true })
  end

  private

    def is_allowed
      render_error :reason => 'access_denied' if !@current_user.superadmin? && !AppConfig.backups.allow_for_users || !@current_user.can_backup_ve?
    end

    def backups_list(virtual_server)
      backups = virtual_server.backups
      backups.map! do |backup|
        {
          :id => backup.id,
          :name => backup.name,
          :description => backup.description,
          :size => backup.size,
          :archive_date => local_datetime(backup.date),
        }
      end
    end

    def set_server_by_id
      @virtual_server = VirtualServer.find_by_id(params[:id])
      render_error :reason => 'object_not_found' if !@virtual_server or !@current_user.can_control(@virtual_server)
    end

    def set_backup_by_id
      @backup = Backup.find_by_id(params[:id])
      unless @backup
        render_error :reason => 'object_not_found' if !@backup
      else
        @virtual_server = @backup.virtual_server if !@backup
      end
    end
end
