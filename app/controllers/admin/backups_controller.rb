class Admin::BackupsController < Admin::Base
  before_filter :is_allowed

  def list
    @virtual_server = VirtualServer.find_by_id(params[:virtual_server_id])
    redirect_to :controller => 'dashboard' and return if !@virtual_server or !@current_user.can_control(@virtual_server)

    @up_level = '/admin/virtual-servers/show?id=' + @virtual_server.id.to_s
    @backups_list = backups_list(@virtual_server)
  end

  def list_data
    virtual_server = VirtualServer.find_by_id(params[:virtual_server_id])
    redirect_to :controller => 'dashboard' and return if !virtual_server or !@current_user.can_control(virtual_server)

    render :json => { :data => backups_list(virtual_server) }
  end

  def delete
    objects_group_operation(Backup, :delete_physically)
  end

  def create
    virtual_server = VirtualServer.find_by_id(params[:virtual_server_id])
    redirect_to :controller => 'dashboard' and return if !virtual_server or !@current_user.can_control(virtual_server)

    if @current_user.limit_reached?(:limit_backups, virtual_server.backups.count)
      render :json => { :success => false, :message => t('admin.backups.form.create.limit_reached') } and return
    end

    Backup.create_backup virtual_server, params[:ve_state], params[:description]
    render :json => { :success => true }
  end

  def restore
    backup = Backup.find_by_id(params[:id])
    virtual_server = backup.virtual_server
    redirect_to :controller => 'dashboard' and return if !virtual_server or !@current_user.can_control(virtual_server)

    backup.restore virtual_server

    render :json => { :success => true }
  end

  private

    def is_allowed
      if !@current_user.superadmin? && !AppConfig.backups.allow_for_users || !@current_user.can_backup_ve?
        redirect_to :controller => 'admin/dashboard'
      end
    end
end
