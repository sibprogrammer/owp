class Admin::TasksController < Admin::Base
  before_filter :superadmin_required
  
  def status
    job = BackgroundJob.find_last_by_status(BackgroundJob::RUNNING)
    render :json => { :message => job ? job.t_description : '' }
  end
  
  def list
    @up_level = '/admin/dashboard'
    @tasks_list = tasks_list
  end
  
  def list_data
    render :json => { :data => tasks_list }  
  end
  
  private
  
    def tasks_list
      tasks = BackgroundJob.all(:limit => 100, :order => 'id DESC')
      tasks.map! { |item| {
        :id => item.id,
        :status => item.status,
        :description => item.t_description
      }}
    end
  
end
