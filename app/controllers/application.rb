# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # filter out password parameters from log files
  filter_parameter_logging :password

  helper :all # include all helpers, all the time

  include AuthenticatedSystem

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  #protect_from_forgery # :secret => 'ca592873eb4aeaa58effb6b48920e979'

  # See ActionController::Base for details
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password").
  # filter_parameter_logging :password

  before_filter :set_locale, :set_product_name, :set_response_format, :set_extjs_base, :set_remote_ip

  protected

    def set_locale
      if AppConfig.locale.single
        I18n.locale = I18n.default_locale
      elsif params[:locale] && I18n.available_locales.include?(params[:locale].to_sym)
        cookies['locale'] = { :value => params[:locale], :expires => 1.year.from_now }
        I18n.locale = params[:locale].to_sym
      elsif cookies['locale'] && I18n.available_locales.include?(cookies['locale'].to_sym)
        I18n.locale = cookies['locale'].to_sym
      end
    end

    def set_product_name
      @product_name = PRODUCT_NAME
      @product_name += AppConfig.branding.show_version ? (' ' + PRODUCT_VERSION) : ''
    end

    def set_extjs_base
      @extjs_base_url = AppConfig.extjs.cdn.enabled ? AppConfig.extjs.cdn.base_url : '/ext'
    end

    def set_remote_ip
      EventLog.remote_ip = request.remote_ip
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

    def iphone?
      return false unless AppConfig.mobile.special_ui
      agent = request.env["HTTP_USER_AGENT"]
      agent && !agent[/iPad/] && (agent[/(Mobile\/.+Safari)/] || agent[/Android/])
    end

    def set_response_format
      request.format = 'iphone'.to_sym if iphone?
    end

    def get_stats
      [
        [
          'user.png',
          t('admin.dashboard.stats_grid.parameter.panel_users'),
          User.count
        ], [
          'server.png',
          t('admin.dashboard.stats_grid.parameter.hardware_servers'),
          HardwareServer.count
        ], [
          'server.png',
          t('admin.dashboard.stats_grid.parameter.virtual_servers'),
          VirtualServer.count
        ], [
          'run.png',
          t('admin.dashboard.stats_grid.parameter.virtual_servers_running'),
          VirtualServer.count(:conditions => "state = 'running'")
        ], [
          'stop.png',
          t('admin.dashboard.stats_grid.parameter.virtual_servers_stopped'),
          VirtualServer.count(:conditions => "state = 'stopped'")
        ], [
          'clock_red.png',
          t('admin.dashboard.stats_grid.parameter.virtual_servers_expired'),
          VirtualServer.count(:conditions => ["expiration_date < ?", Date.today])
        ], [
          'help.png',
          t('admin.dashboard.stats_grid.parameter.opened_requests'),
          Request.count(:conditions => ["opened = ?", true])
        ]
      ]
    end

    def servers_list
      if @current_user.superadmin?
        @servers_list = HardwareServer.all
        @servers_list.map! do |server|
          {
            :cls => 'menu-item',
            :text => server.host,
            :href => base_url + '/admin/hardware-servers/show?id=' + server.id.to_s,
            :icon => base_url + '/images/server.png',
            :leaf => true,
            :server_id => server.id.to_s,
          }
        end
      else
        @servers_list = @current_user.virtual_servers
        @servers_list = @servers_list.map do |server|
          {
            :cls => 'menu-item',
            :text => ('#' + server.identity.to_s) + (server.host_name.blank? ? '' : (' - ' + server.host_name)),
            :href => base_url + '/admin/virtual-servers/show?id=' + server.id.to_s,
            :icon => base_url + '/images/server.png',
            :leaf => true,
            :server_id => server.id.to_s,
          }
        end
      end
    end

    def local_datetime(datetime)
      datetime.localtime.strftime("%Y.%m.%d %H:%M:%S")
    end

    def local_date(datetime)
      datetime.localtime.strftime("%Y.%m.%d")
    end

    def format_date(date)
      date.strftime("%Y.%m.%d")
    end

    def base_url
      ActionController::Base.relative_url_root.to_s
    end

end
