class Iphone::EventLogController < Iphone::Base
  before_filter :is_allowed

  def list
    @page_title = t('admin.event_log.title')
    @events = EventLog.all(:limit => 100, :order => 'id DESC')
  end

  private

    def is_allowed
      redirect_to :controller => 'iphone/dashboard' if !@current_user.can_view_logs? && !@current_user.can_manage_logs?
    end

end
