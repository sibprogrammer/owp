class Admin::UsersController < AdminController
  
  def save_profile    
    user = User.authenticate(@current_user.login, params[:current_password])
    
    if !user
      render :json => { :success => false, :errors => [['current_password', t('admin.my_profile.bad_current_password')]] }
      return
    end
        
    user.password = params[:password]
    user.password_confirmation = params[:confirm_password]
    
    if user.save
      render :json => { :success => true }  
    else
      render :json => { :success => false, :errors => user.errors }
    end
  end
  
end
