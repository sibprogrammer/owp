class Admin::TasksController < Admin::Base
  before_filter :superadmin_required
  
  def status
    job = BackgroundJob.find_last_by_status(BackgroundJob::RUNNING)
    render :json => { :message => job ? job.t_description : '' }
  end
  
  def list
    @up_level = '/admin/dashboard'
  end
  
  def list_data
    @tasks = BackgroundJob.all
    @tasks.map! { |item| {
      :id => item.id,
      :status => item.status,
      :description => item.t_description
    }}
    render :json => { :data => @tasks }  
  end
  
end
