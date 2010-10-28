class Admin::UsersController < Admin::Base
  before_filter :is_allowed, :except => :save_profile
  
  def save_profile
    if !params[:password].blank?
      if !User.authenticate(@current_user.login, params[:current_password])
        @current_user.errors.add(:current_password, t('admin.my_profile.bad_current_password'))
      end
    else
      params.delete(:password)
      params.delete(:password_confirmation)
    end
    
    params.delete(:role_id)
    @current_user.attributes = params
    
    if @current_user.errors.empty? && @current_user.save
      EventLog.info("user.profile_updated", { :login => @current_user.login })
      render :json => { :success => true }  
    else
      render :json => { :success => false, :form_errors => @current_user.errors }
    end
  end
  
  def list
    @up_level = '/admin/dashboard'
    @users_list = users_list
  end
  
  def list_data
    render :json => { :data => users_list }
  end
  
  def delete
    params[:ids].split(',').each { |id|
      user = User.find(id)
      login = user.login
      
      if !user.destroy
        render :json => { :success => false }  
        return
      end
      
      EventLog.info("user.removed", { :login => login })
    }
    
    render :json => { :success => true }
  end
  
  def update
    user = (params[:id].to_i > 0) ? User.find_by_id(params[:id]) : User.new
    is_new = user.new_record?
    user.attributes = params
    
    if user.save
      EventLog.info(is_new ? "user.created" : "user.updated", { :login => user.login })
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
      :role_id => user.role_id,
      :contact_name => user.contact_name,
      :email => user.email,
    }}
  end
  
  def change_state
    params[:ids].split(',').each { |id|
      user = User.find(id) 
      
      case params[:command]  
        when 'enable' then user.enabled = true
        when 'disable' then user.enabled = false
      end
      
      if !user.save
        render :json => { :success => false }  
        return
      end
      
      EventLog.info("user.enabled", { :login => user.login }) if user.enabled
      EventLog.info("user.disabled", { :login => user.login }) if !user.enabled
    }
    
    render :json => { :success => true }
  end
  
  private
  
    def users_list
      users = User.all
      users.map! { |user| {
        :id => user.id,
        :enabled => user.enabled,
        :login => user.login,
        :role => user.role.display_name,
        :created_at => local_datetime(user.created_at),
        :contact_name => user.contact_name,
        :email => user.email,
      }}
    end
  
    def is_allowed
      redirect_to :controller => 'admin/dashboard' if !@current_user.can_manage_users?
    end
end
