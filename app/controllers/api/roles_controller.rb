class Api::RolesController < Api::Base
  before_filter :is_allowed

  def list
    render_object_result(Role.all, :root => 'roles')
  end

  private

    def is_allowed
      render_error :reason => 'access_denied' if !@current_user.can_manage_users?
    end

end