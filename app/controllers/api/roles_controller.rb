class Api::RolesController < Api::Base
  before_filter :is_allowed

  def index
    methods_list
  end

  def list
    render_object_result(Role.all, :root => 'roles')
  end

  private

    def is_allowed
      redirect_to :controller => 'error', :reason => 'access_denied' if !@current_user.can_manage_users?
    end

end