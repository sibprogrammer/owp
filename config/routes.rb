ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.

  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  map.login '/login', :controller => 'sessions', :action => 'new'
  map.restore_password '/restore-password', :controller => 'sessions', :action => 'restore_password'
  map.reset_password '/reset-password', :controller => 'sessions', :action => 'reset_password'

  map.resource :session

  map.namespace :admin do |admin|
    %w{
      hardware_servers
      virtual_servers
      server_templates
      os_templates
      event_log
      ip_addresses
      ip_pools
    }.each do |controller|
      admin.connect "/#{controller.sub('_', '-')}/:action", :controller => controller
    end
  end

  map.connect ':controller/:action'

  map.root :login
  map.connect '*anything', :controller => 'sessions', :action => 'new'
end
