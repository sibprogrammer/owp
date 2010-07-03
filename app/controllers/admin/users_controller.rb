class Admin::UsersController < Admin::Base
  before_filter :superadmin_required, :except => :save_profile
  
  def save_profile    
    user = User.authenticate(@current_user.login, params[:current_password])
    
    if !user
      render :json => { :success => false, :form_errors => [['current_password', t('admin.my_profile.bad_current_password')]] }
      return
    end
    
    user.attributes = params
    
    if user.save
      render :json => { :success => true }  
    else
      render :json => { :success => false, :form_errors => user.errors }
    end
  end
  
  def list
    @up_level = '/admin/dashboard'
  end
  
  def list_data
    users = User.all
    users.map! { |user| {
      :id => user.id,
      :login => user.login,
      :role_type => t('admin.users.role.' + (1 == user.role_type ? 'infrastructure_admin' : 'virtual_server_owner')),
      :created_at => user.created_at.strftime("%Y.%m.%d %H:%M:%S"),
    }}
    render :json => { :data => users }  
  end
  
  def delete
    params[:ids].split(',').each { |id|
      user = User.find(id) 
      
      if !user.delete
        render :json => { :success => false }  
        return
      end
    }
    
    render :json => { :success => true }
  end
  
  def update
    user = (params[:id].to_i > 0) ? User.find_by_id(params[:id]) : User.new
    user.attributes = params
    
    if user.save
      render :json => { :success => true }  
    else
      render :json => { :success => false, :form_errors => user.errors }
    end
  end
  
  def load_data
    user = User.find_by_id(params[:id])
    redirect_to :controller => 'users', :action => 'list' and return if !user
    
    render :json => { :success => true, :data => {
      :login => user.login,
      :role_type => user.role_type,
    }}
  end
  
end
