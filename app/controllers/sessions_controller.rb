class SessionsController < ApplicationController
  layout :app_layout

  def new
    @available_locales = I18n.available_locales.map {
      |locale| [locale.to_s, I18n.t('language.title', :locale => locale) + " (#{locale})"]
    }.sort

    if request.post?
      logout_keeping_session!
      user = User.authenticate(params[:login], params[:password])
      if user && user.enabled && !user.ip_restriction?(request.remote_ip)
        EventLog.info("user.login.ok", { :login => user.login })
        self.current_user = user
        new_cookie_flag = (params[:remember_me] == "on")
        handle_remember_cookie! new_cookie_flag
        respond_to do |format|
          format.html do
            if params[:plain_post].blank?
              render :json => { :success => true }
            else
              redirect_to :controller => 'admin/dashboard'
            end
          end
          format.iphone { redirect_to :controller => 'iphone/dashboard' }
        end
      else
        if user and !user.enabled
          message =  t('login.locked_user')
          EventLog.error("user.login.locked_user", { :login => user.login })
        elsif user and user.ip_restriction?(request.remote_ip)
          message =  t('login.ip_restricted')
          EventLog.error("user.login.ip_restricted", { :login => user.login })
        else
          message = t('login.bad_login')
          known_user = User.find_by_login(params[:login])
          if known_user
            EventLog.error("user.login.bad_password", { :login => known_user.login })
          else
            EventLog.error("user.login.bad_login")
          end
        end

        logger.warn "Failed login for '#{params[:login]}' from #{request.remote_ip} at #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
        respond_to do |format|
          format.html { render :json => { :success => false, :message => message } }
          format.iphone { flash.now[:error] = message }
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to :controller => 'admin/dashboard' if logged_in? }
        format.iphone do
          redirect_to :controller => 'iphone/dashboard' if logged_in?
        end
      end
    end

    @page_title = t('login.page_title') if iphone?
  end

  def destroy
    EventLog.info("user.logout", { :login => current_user.login }) if current_user
    logout_killing_session!
    redirect_back_or_default login_path
  end

  def restore_password
    if request.post?
      user = User.find_by_login(params[:login])
      render(:json => { :success => false, :message => t('restore_password.error.user_not_found') }) and return if !user
      render(:json => { :success => false, :message => t('restore_password.error.no_email') }) and return if user.email.blank?

      UserMailer.deliver_restore_password_email(user, request.url.sub('/restore-password', '/reset-password'))
      render :json => { :success => true, :message => t('restore_password.restore_link_sent') }
    end
  end

  def reset_password
    if params.key?(:user_id) and params.key?(:hash)
      user = User.find(params[:user_id])
      if user
        hash = Digest::SHA1.hexdigest(user.crypted_password + user.login)
        @user = user if hash == params[:hash]
        @hash = hash
      end
    end

    redirect_to login_path and return if !@user

    if request.post?
      @user.password = params[:password]
      @user.password_confirmation = params[:password_confirmation]

      if @user.save
        render :json => { :success => true, :message => t('reset_password.password_changed') }
      else
        render :json => { :success => false, :form_errors => @user.errors }
      end
    end
  end

  private

    def app_layout
      iphone? ? 'iphone' : 'application'
    end

end
