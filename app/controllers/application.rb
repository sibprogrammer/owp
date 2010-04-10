# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  
  include AuthenticatedSystem

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  #protect_from_forgery # :secret => 'ca592873eb4aeaa58effb6b48920e979'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password
    
  before_filter :set_locale
    
  protected  
  
    def set_locale
      if params[:locale] && I18n.available_locales.include?(params[:locale].to_sym)
        cookies['locale'] = { :value => params[:locale], :expires => 1.year.from_now }
        I18n.locale = params[:locale].to_sym
      elsif cookies['locale'] && I18n.available_locales.include?(cookies['locale'].to_sym)
        I18n.locale = cookies['locale'].to_sym
      end
    end
  
    def log_error(exception)
      super
      EventLog.error("internal_error", { :message => exception.message })
    end
  
    def rescue_action_locally(exception)
      if request.xhr?
        ajax_request_handler(exception)
      else
        super
      end
    end
    
    def rescue_action_in_public(exception)
      if request.xhr?
        ajax_request_handler(exception)
      else
        super
      end
    end
  
    def ajax_request_handler(exception)
      message = t("admin.events.internal_error", { :message => exception.message })
      render :json => { :success => false, :message => message.gsub(/\n/, '<br />') }
    end
  
end
