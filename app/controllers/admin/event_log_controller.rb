class Admin::EventLogController < Admin::Base
  before_filter :superadmin_required
  
  def list
    @up_level = '/admin/dashboard'
    @events_list = events_list
  end
  
  def list_data
    render :json => { :data => events_list }
  end
  
  def clear
    render :json => { :success => EventLog.delete_all }
  end
  
  private
  
    def events_list
      events = EventLog.all(:limit => 100, :order => 'id DESC')
      events.map! { |item| {
        :id => item.id,
        :message => item.html_message,
        :level => item.level,
        :created_at => item.created_at.strftime("%Y.%m.%d %H:%M:%S"),
      }}
    end
  
end
