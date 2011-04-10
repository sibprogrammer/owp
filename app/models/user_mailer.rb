require 'digest/sha1'

class UserMailer < ActionMailer::Base

  def restore_password_email(user, link)
    recipients user.email
    subject I18n.t('restore_password.mail.restore_link.subject')
    body :link => (link + "?user_id=#{user.id}&hash=" + Digest::SHA1.hexdigest(user.crypted_password + user.login))
  end

  def request_email(user, request)
    recipients user.email
    subject I18n.t('admin.requests.mail.new_request.subject', :id => request.id)
    body :request => request
  end

  def request_comment_email(user, comment)
    recipients user.email
    subject I18n.t('admin.requests.mail.new_comment.subject', :request_id => comment.request_id)
    body :comment => comment
  end

end
