class Admin::Base < ApplicationController
  layout 'admin'  
  before_filter :login_required, :servers_list
  
  protected
  
    def superadmin_required
      redirect_to :controller => 'admin/dashboard' if !@current_user.superadmin?
    end
    
end
