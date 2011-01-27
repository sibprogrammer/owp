class Api::ErrorController < Api::Base

  def index
    allowed_reasons = [ 'object_not_found', 'access_denied' ]
    @reason = allowed_reasons.include?(params[:reason]) ? params[:reason] : 'unknown_error'
    @error = t('api.error.' + @reason)
  end

end
