class EventLog < ActiveRecord::Base
  
  DEBUG   = 0
  INFO    = 1
  WARN    = 2
  ERROR   = 3
  FATAL   = 4
  UNKNOWN = 5
  
  def self.info(message, params = {})
    self.log(message, params, INFO)
  end
  
  def self.debug(message, params = {})
    self.log(message, params, DEBUG)
  end
  
  def self.error(message, params = {})
    self.log(message, params, ERROR)
  end
  
  def self.log(message, params = {}, level = DEBUG)
    record = self.new(:message => message, :level => level, :params => params.blank? ? '' : Marshal.dump(params))
    record.save
    RAILS_DEFAULT_LOGGER.add(level, record.t_message(:en))
    
    if EventLog.count > AppConfig.log.max_records
      limit_record = EventLog.find(:first, :order => "id DESC", :offset => AppConfig.log.max_records)
      EventLog.delete_all(["id <= ?", limit_record.id])
    end
    true
  end
  
  def t_message(locale = I18n.locale)
    params = self.params.blank? ? {} : Marshal.load(self.params)
    params[:locale] = locale
    I18n.t("admin.events." + self.message, params)
  end
  
  def html_message
    params = self.params.blank? ? {} : Marshal.load(self.params)
    params.each { |key,item|
      item = CGI.escapeHTML(item.to_s)
      item = "<b>#{item}</b>" if item !~ /\s/
      params[key] = item
    }
    I18n.t("admin.events." + self.message, params).gsub(/\n/, '<br />')
  end
  
end
