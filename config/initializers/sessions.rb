require 'cgi'
require 'cgi/session'

class CGI::Session::CookieStore

  def restore
    @original = read_cookie
    @data = unmarshal(@original) || {}
  rescue CGI::Session::CookieStore::TamperedWithCookie
    Rails.logger.warn "TamperedWithCookie: old or invalid cookie was used."
    @data = {}
  end

end

ActionController::Base.session = {
  :session_key => '_owp_session',
  :secret => ENV["SECRET_TOKEN"] ? ENV["SECRET_TOKEN"] : ActiveSupport::SecureRandom.hex(64),
}
