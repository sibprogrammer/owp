class Admin::UsersController < AdminController
  
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
  
end
