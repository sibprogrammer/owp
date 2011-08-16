class Comment < ActiveRecord::Base
  belongs_to :request
  belongs_to :user

  validates_presence_of :content

  attr_accessible :content

  after_create { |record| EventLog.info("comment.created", { :request_id => record.request_id }) }
  after_create :email_notification

  private

    def email_notification
      users = User.all.select(&:can_handle_requests?)
      users << request.user if request.user.id != user.id

      users.each do |user|
        next if user.email.blank?
        UserMailer.deliver_request_comment_email(user, self)
      end
    end

end
