class Admin::EventLogController < Admin::Base
  before_filter :is_allowed
  before_filter :get_events, :only => [ :list, :list_data ]

  def list
    @up_level = '/admin/dashboard'
  end

  def list_data
    render :json => @events
  end

  def clear
    redirect_to :controller => 'admin/dashboard' if !@current_user.can_manage_logs?
    render :json => { :success => EventLog.delete_all }
  end

  private

    def get_events
      filter = { :limit => 100, :order => 'id DESC' }
      @events = EventLog.all(filter).to_json(:except => [ :params, :message ], :methods => :t_message)
    end

    def is_allowed
      redirect_to :controller => 'admin/dashboard' if !@current_user.can_view_logs? && !@current_user.can_manage_logs?
    end

end
