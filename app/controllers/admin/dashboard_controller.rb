require 'net/http'
require 'rexml/document'

class Admin::DashboardController < Admin::Base
  
  def index 
    @stats_data = get_stats
    @updates = get_updates
  end
  
  private
  
  def get_stats
    [
      [
        t('admin.dashboard.stats_grid.parameter.panel_users'),
        User.count
      ], [
        t('admin.dashboard.stats_grid.parameter.hardware_servers'),
        HardwareServer.count
      ], [
        t('admin.dashboard.stats_grid.parameter.virtual_servers'),
        VirtualServer.count
      ], [
        t('admin.dashboard.stats_grid.parameter.virtual_servers_running'),
        VirtualServer.count(:conditions => "state = 'running'")
      ], [
        t('admin.dashboard.stats_grid.parameter.virtual_servers_stopped'),
        VirtualServer.count(:conditions => "state = 'stopped'")
      ], [
        t('admin.dashboard.stats_grid.parameter.os_templates'),
        OsTemplate.count
      ]
    ]
  end
  
  def get_updates
    return if AppConfig.updates.disabled 
    
    check_date = Rails.cache.fetch('updates_date') { Time.now }
    
    begin
      latest_update = Rails.cache.fetch('updates', :force => (Time.now - check_date > AppConfig.updates.period)) do
        xml = Hash.from_xml(Net::HTTP.get_response(URI.parse(AppConfig.updates.url)).body)
        logger.info "Updates information was obtained."
        Rails.cache.write('updates_date', Time.now)
        xml['updates']['latest']
      end
    rescue Exception => e
      logger.info "Failed to obtain updates. Error: #{e}."
      Rails.cache.write('updates', {})
      Rails.cache.write('updates_date', Time.now)
      return
    end
    
    if latest_update and latest_update.key?('version') and latest_update['version'] > PRODUCT_VERSION 
      { :version => latest_update['version'], :update_command => latest_update['upgrade_command'] }
    else
      nil
    end
  end
  
end
