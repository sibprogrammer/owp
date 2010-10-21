class Admin::EventLogController < Admin::Base
  before_filter :is_allowed
  
  def list
    @up_level = '/admin/dashboard'
    @events_list = events_list
  end
  
  def list_data
    render :json => { :data => events_list }
  end
  
  def clear
    redirect_to :controller => 'admin/dashboard' if !@current_user.can_manage_logs?
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
  
    def is_allowed
      redirect_to :controller => 'admin/dashboard' if !@current_user.can_view_logs? && !@current_user.can_manage_logs?
    end
  
end
