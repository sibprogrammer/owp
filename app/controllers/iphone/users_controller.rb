class Iphone::UsersController < Iphone::Base
  
  def profile
    @page_title = t('admin.my_profile.title')
    
    if request.post?
      user = User.authenticate(@current_user.login, params[:current_password])
      
      if !user
        flash.now[:error] = t('admin.my_profile.bad_current_password')
        return
      end
      
      user.attributes = params
      
      if user.save
        redirect_to :controller => 'iphone/dashboard'
      else
        flash.now[:error] = user.errors
      end
    end
  end
  
  def list
    @page_title = t('admin.users.title')
    
    @users = User.all(:order => 'login')
    @users.map! { |user| {
      :id => user.id,
      :login => user.login,
      :role_type => t('admin.users.role.' + (1 == user.role_type ? 'infrastructure_admin' : 'virtual_server_owner')),
    }}
  end
  
end
