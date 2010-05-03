class Iphone::DashboardController < Iphone::Base
  
  def index
    @show_back = true
    @show_logout = true
    render :layout => 'iphone'
  end
  
  def stats
    @stats = get_stats
  end
  
end
