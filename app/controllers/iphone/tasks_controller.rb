class Iphone::TasksController < Iphone::Base
  
  def list
    @page_title = t('admin.task.title')
    
    @tasks = BackgroundJob.all(:limit => 100, :order => 'id DESC')
    @tasks.map! { |item| {
      :id => item.id,
      :status => item.status,
      :description => item.t_description
    }}
  end
  
end
