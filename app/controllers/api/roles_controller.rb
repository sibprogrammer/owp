class Api::RolesController < Api::Base
  before_filter :is_allowed

  def list
    render_object_result(Role.all, :root => 'roles')
  end

  def get_by_name
    role = Role.find_by_name(params[:name])
    render_error :reason => 'object_not_found' if !role
    render_object_result(role) if role
  end

  private

    def is_allowed
      render_error :reason => 'access_denied' if !@current_user.can_manage_users?
    end

end
