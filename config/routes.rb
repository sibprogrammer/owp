ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.
  
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'
  map.login '/login', :controller => 'sessions', :action => 'new'

  map.resource :session

  map.namespace :admin do |admin|
    admin.connect '/hardware-servers/:action', :controller => 'hardware_servers'
    admin.connect '/virtual-servers/:action', :controller => 'virtual_servers'
    admin.connect '/os-templates/:action', :controller => 'os_templates'
    admin.connect '/event-log/:action', :controller => 'event_log'
  end
  
  map.connect ':controller/:action'
  
  map.root :login
  map.connect '*anything', :controller => 'sessions', :action => 'new'
end
