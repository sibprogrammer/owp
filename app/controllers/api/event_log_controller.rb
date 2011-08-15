class Api::EventLogController < Api::Base
  before_filter :is_allowed

  def list
    events = EventLog.all(:limit => 100, :order => 'id DESC')
    render_object_result(events, :root => 'events', :methods => :t_message, :except => [ :params ])
  end

  private

    def is_allowed
      render_error :reason => 'access_denied' if !@current_user.can_view_logs? && !@current_user.can_manage_logs?
    end

end
