class Iphone::DashboardController < Iphone::Base

  def index
    @page_title = t('admin.dashboard.title')
    @show_home_button = false
  end

  def stats
    @page_title = t('admin.dashboard.stats_grid.title')
    @stats = get_stats
  end

end
