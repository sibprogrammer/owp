class Iphone::TasksController < Iphone::Base
  before_filter :is_allowed

  def list
    @page_title = t('admin.task.title')
    @tasks = BackgroundJob.all(:limit => 100, :order => 'id DESC')
  end

  private

    def is_allowed
      redirect_to :controller => 'iphone/dashboard' if !@current_user.can_view_tasks?
    end

end
