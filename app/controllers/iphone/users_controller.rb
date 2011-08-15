class Iphone::UsersController < Iphone::Base
  before_filter :is_allowed, :except => [ :profile ]

  def profile
    @page_title = t('admin.my_profile.title')

    if request.post?
      if !params[:password].blank?
        if !User.authenticate(@current_user.login, params[:current_password])
          @current_user.errors.add(:current_password, t('admin.my_profile.bad_current_password'))
        end
      else
        params.delete(:password)
        params.delete(:password_confirmation)
      end

      @current_user.attributes = params

      if @current_user.errors.empty? && @current_user.save
        redirect_to :controller => 'iphone/dashboard'
      else
        flash.now[:error] = @current_user.errors
      end
    end
  end

  def list
    @page_title = t('admin.users.title')
    @users = User.all(:order => 'login')
  end

  private

    def is_allowed
      redirect_to :controller => 'iphone/dashboard' if !@current_user.can_manage_users?
    end

end
