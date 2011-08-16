class Admin::TasksController < Admin::Base
  before_filter :is_allowed
  before_filter :get_tasks, :only => [ :list, :list_data ]

  def status
    job = BackgroundJob.find_last_by_status(BackgroundJob::RUNNING)
    render :json => { :message => job ? job.t_description : '' }
  end

  def list
    @up_level = '/admin/dashboard'
  end

  def list_data
    render :json => @tasks
  end

  private

    def get_tasks
      filter = { :limit => 100, :order => 'id DESC' }
      @tasks = BackgroundJob.all(filter).to_json(:except => [ :params, :description ], :methods => :t_description)
    end

    def is_allowed
      redirect_to :controller => 'admin/dashboard' if !@current_user.can_view_tasks?
    end

end
