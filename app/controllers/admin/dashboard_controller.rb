require 'net/http'
require 'rexml/document'
require 'timeout'

class Admin::DashboardController < Admin::Base

  def index
    @stats_data = get_stats
    @updates = get_updates
    @watchdog_alive = Watchdog.alive
  end

  private

  def get_updates
    return if AppConfig.updates.disabled

    check_date = Rails.cache.fetch('updates_date') { Time.now }

    begin
      latest_update = Rails.cache.fetch('updates', :force => (Time.now - check_date > AppConfig.updates.period)) do
        xml = nil
        Timeout::timeout(3) do
          xml = Hash.from_xml(Net::HTTP.get_response(URI.parse(AppConfig.updates.url)).body)
        end
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
