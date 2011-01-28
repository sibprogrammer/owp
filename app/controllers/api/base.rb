class Api::Base < ApplicationController
  before_filter :login_required

  def index
    methods_list
  end

  protected

    def current_user
      @current_user ||= login_from_basic_auth unless @current_user == false
    end

    def set_response_format
      request.format = 'xml'.to_sym
    end

    def superadmin_required
      redirect_to :controller => 'error' if !@current_user.superadmin?
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

    def methods_list
      result = {}
      action_methods.delete('index').each { |method| result[method] = '' }
      render_object_result(result, :root => 'methods')
    end
  
end
