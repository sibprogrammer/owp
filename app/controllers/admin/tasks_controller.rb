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
    @tasks = BackgroundJob.all(:limit => 100, :order => 'id DESC')
    @tasks.map! { |item| {
      :id => item.id,
      :status => item.status,
      :description => item.t_description
    }}
    render :json => { :data => @tasks }  
  end
  
end
