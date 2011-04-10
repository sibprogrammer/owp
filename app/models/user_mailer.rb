require 'digest/sha1'

class UserMailer < ActionMailer::Base

  def restore_password_email(user, link)
    recipients user.email
    subject I18n.t('restore_password.mail.restore_link.subject')
    body :link => (link + "?user_id=#{user.id}&hash=" + Digest::SHA1.hexdigest(user.crypted_password + user.login))
  end

end
