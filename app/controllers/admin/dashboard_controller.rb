class Admin::DashboardController < AdminController
  
  def index 
    @stats_data = get_stats
  end
  
  private
  
  def get_stats
    [
      [
        t('admin.dashboard.stats_grid.parameter.panel_users'),
        User.count
      ], [
        t('admin.dashboard.stats_grid.parameter.hardware_servers'),
        HardwareServer.count
      ], [
        t('admin.dashboard.stats_grid.parameter.virtual_servers'),
        VirtualServer.count
      ], [
        t('admin.dashboard.stats_grid.parameter.virtual_servers_running'),
        VirtualServer.count(:conditions => "state = 'running'")
      ], [
        t('admin.dashboard.stats_grid.parameter.virtual_servers_stopped'),
        VirtualServer.count(:conditions => "state = 'stopped'")
      ], [
        t('admin.dashboard.stats_grid.parameter.os_templates'),
        OsTemplate.count
      ]
    ]
  end
  
end
