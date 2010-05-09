class Iphone::DashboardController < Iphone::Base
  
  def index
    @page_title = t('admin.dashboard.title')
    render :layout => 'iphone'
  end
  
  def stats
    @stats = get_stats
  end
  
end
