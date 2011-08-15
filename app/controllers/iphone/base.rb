class Iphone::Base < ApplicationController
  before_filter :login_required, :servers_list, :prepare_navigation
  layout 'iphone'

  protected

    def superadmin_required
      redirect_to :controller => 'iphone/dashboard' if !@current_user.superadmin?
    end

    def access_denied
      respond_to do |format|
        format.iphone do
          store_location
          redirect_to '/session/new'
        end
      end
    end

    def prepare_navigation
      @show_home_button = true
    end

end
