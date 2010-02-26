class Admin::EventLogController < AdminController
  before_filter :superadmin_required
  
  def list
    @up_level = '/admin/dashboard'
  end
  
  def list_data
    @events = EventLog.all(:limit => 100, :order => 'id DESC')
    @events.map! { |item| {
      :id => item.id,
      :message => item.t_message,
      :level => item.level,
      :created_at => item.created_at.strftime("%Y.%m.%d %H:%M:%S"),
    }}
    render :json => { :data => @events }  
  end
  
  def clear
    render :json => { :success => EventLog.delete_all }
  end
  
end
