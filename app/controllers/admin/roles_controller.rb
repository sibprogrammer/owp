class Admin::RolesController < Admin::Base
  before_filter :is_allowed

  def list
    @up_level = '/admin/users/list'
    @roles_list = roles_list
    @permissions = Permission.all.map(&:name)
    @limits = { 'limit_backups' => '' }
  end

  def list_data
    render :json => { :data => roles_list }
  end

  def delete
    objects_group_operation(Role, :destroy)
  end

  def update
    role = (params[:id].to_i > 0) ? Role.find_by_id(params[:id]) : Role.new
    is_new = role.new_record?
    role.attributes = params

    role.permissions = []
    params[:permissions] = params[:permissions] || []
    params[:permissions].each { |key,value| role.permissions << Permission.find_by_name(key) }
    role.limit_backups = params[:limits][:limit_backups]

    if role.built_in || role.save
      EventLog.info(is_new ? "role.created" : "role.updated", { :name => role.name })
      render :json => { :success => true }
    else
      render :json => { :success => false, :form_errors => role.errors }
    end
  end

  def load_data
    role = Role.find_by_id(params[:id])
    redirect_to :controller => 'roles', :action => 'list' and return if !role

    data = { :name => role.display_name, :built_in => role.built_in }
    role.permissions.each { |permission| data["permissions[#{permission.name}]"] = true }

    data["limits[limit_backups]"] = -1 == role.limit_backups ? '' : role.limit_backups;

    render :json => { :success => true, :data => data }
  end

  private

    def roles_list
      roles = Role.all
      roles.map! do |role|
        {
          :id => role.id,
          :name => role.display_name,
          :built_in => role.built_in,
          :users => role.users.count,
        }
      end
    end

    def is_allowed
      redirect_to :controller => 'admin/dashboard' if !@current_user.can_manage_users?
    end

end
