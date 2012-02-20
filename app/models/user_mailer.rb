require 'digest/sha1'

class UserMailer < ActionMailer::Base

  def restore_password_email(user, link)
    setup_common_fields(user.email)
    subject I18n.t('restore_password.mail.restore_link.subject')
    body :link => (link + "?user_id=#{user.id}&hash=" + Digest::SHA1.hexdigest(user.crypted_password + user.login))
  end

  def request_email(user, request)
    setup_common_fields(user.email)
    subject I18n.t('admin.requests.mail.new_request.subject', :id => request.id)
    body :request => request
  end

  def request_comment_email(user, comment)
    setup_common_fields(user.email)
    subject I18n.t('admin.requests.mail.new_comment.subject', :request_id => comment.request_id)
    body :comment => comment
  end

  private

    def setup_common_fields(email)
      from_address = AppConfig.email.from
      from from_address if from_address
      recipients email
    end

end
