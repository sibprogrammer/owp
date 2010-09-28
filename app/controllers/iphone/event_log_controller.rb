class Iphone::EventLogController < Iphone::Base
  
  def list
    @page_title = t('admin.event_log.title')
    
    @events = EventLog.all(:limit => 100, :order => 'id DESC')
    @events.map! { |item| {
      :id => item.id,
      :message => item.html_message,
      :level => item.level,
      :created_at => item.created_at.strftime("%Y.%m.%d %H:%M:%S"),
    }}
  end
  
end
