class Api::UsersController < Api::Base
  before_filter :is_allowed, :set_hidden_attrs
  before_filter :set_user_by_id, :only => [ :get, :delete, :update, :enable, :disable ]

  def list
    render_object_result(User.all, :root => 'users', :except => @hidden_attrs)
  end

  def get
    render_object_result(@user, :except => @hidden_attrs)
  end

  def get_by_login
    user = User.find_by_login(params[:login])
    render_error :reason => 'object_not_found' if !user
    render_object_result(user, :except => @hidden_attrs) if user
  end

  def delete
    @user.destroy
    render_scalar_result(true)
  end

  def create
    create_or_update_user
  end

  def update
    create_or_update_user
  end

  def enable
    @user.enabled = true
    render_scalar_result(@user.save)
  end

  def disable
    @user.enabled = false
    render_scalar_result(@user.save)
  end

  private

    def is_allowed
      render_error :reason => 'access_denied' if !@current_user.can_manage_users?
    end

    def set_hidden_attrs
      @hidden_attrs = [ :crypted_password, :remember_token, :remember_token_expires_at, :salt, :updated_at ]
    end

    def set_user_by_id
      @user = User.find_by_id(params[:id])
      render_error :reason => 'object_not_found' if !@user
    end

    def create_or_update_user
      @user = User.new unless @user
      params[:password_confirmation] = params[:password]
      @user.attributes = params
      render_object_save_result(@user.save, @user)
    end

end
