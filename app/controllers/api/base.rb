class Api::Base < ApplicationController
  before_filter :login_required

  def index
    result = {}
    action_methods.delete('index').each { |method| result[method] = '' }
    render_object_result(result, :root => 'methods')
  end

  protected

    def current_user
      @current_user ||= login_from_basic_auth unless @current_user == false
    end

    def set_response_format
      request.format = :xml
    end

    def superadmin_required
      render_error :reason => 'access_denied' if !@current_user.superadmin?
    end

    def render_scalar_result(result, details = {})
      output = { :status => result }
      output[:details] = details unless details.blank?
      render :xml => output.to_xml(:root => 'result')
    end

    def render_object_result(object, options = {})
      options[:dasherize] ||= false
      render :xml => object.to_xml(options)
    end

    def render_object_save_result(result, object)
      details = result ? { :id => object.id } : object.errors.collect { |field,error| { :field => field, :error => error } }
      render_scalar_result(result, details)
    end

    def render_error(params = {})
      allowed_reasons = [ 'object_not_found', 'access_denied', 'internal_error' ]
      @reason = allowed_reasons.include?(params[:reason]) ? params[:reason] : 'unknown_error'
      @details = params[:details] if params.has_key?(:details)
      @error = t('api.error.' + @reason)

      render :template => 'api/error/index.rxml'
      return false
    end

    def rescue_action(exception)
      log_error(exception) if logger
      render_error :reason => 'internal_error', :details => exception
    end

end
