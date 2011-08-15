class Request < ActiveRecord::Base
  belongs_to :user
  has_many :comments, :dependent => :destroy

  validates_presence_of :subject, :content

  attr_accessible :subject, :content

  after_create { |record| EventLog.info("request.created", { :id => record.id }) }
  after_create :email_notification
  after_update { |record| EventLog.info("request.updated", { :id => record.id }) }
  after_destroy { |record| EventLog.info("request.removed", { :id => record.id }) }

  private

    def email_notification
      User.all.select(&:can_handle_requests?).each do |admin|
        next if admin.email.blank?
        UserMailer.deliver_request_email(admin, self)
      end
    end

end
