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
    render_error :reason => 'backups.limit_reached' if @current_user.limit_reached?(:limit_backups, @virtual_server.backups.count)
    Backup.create_backup @virtual_server, params[:ve_state], params[:description]

    render_object_result({ :success => true })
  end

  def restore
    @backup.restore
    render_object_result({ :success => true })
  end

  private

  def is_allowed
    render_error :reason => 'access_denied' if !@current_user.superadmin? && !AppConfig.backups.allow_for_users || !@current_user.can_backup_ve?
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