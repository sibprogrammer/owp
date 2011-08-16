class Api::TasksController < Api::Base
  before_filter :is_allowed

  def list
    tasks = BackgroundJob.all(:limit => 100, :order => 'id DESC')
    render_object_result(tasks, :root => 'tasks', :methods => :t_description, :except => [ :params ])
  end

  private

    def is_allowed
      render_error :reason => 'access_denied' if !@current_user.can_view_tasks?
    end

end
