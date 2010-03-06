class SessionsController < ApplicationController

  def new
    if request.post?
      logout_keeping_session!
      user = User.authenticate(params[:login], params[:password])
      if user
        self.current_user = user
        new_cookie_flag = (params[:remember_me] == "on")
        handle_remember_cookie! new_cookie_flag
        render :json => { :success => true }  
      else
        logger.warn "Failed login for '#{params[:login]}' from #{request.remote_ip} at #{Time.now.utc}"
        render :json => { :success => false, :message => t('login.bad_login') } 
      end
    else
      redirect_to :controller => 'admin/dashboard' if logged_in?
    
      @available_locales = I18n.available_locales.map { 
        |locale| [locale.to_s, I18n.t('language.title', :locale => locale) + " (#{locale})"]
      }.sort
    end
  end

  def destroy
    logout_killing_session!
    redirect_back_or_default('/')
  end

end
