class Request < ActiveRecord::Base
  belongs_to :user
  has_many :comments, :dependent => :destroy

  validates_presence_of :subject, :content
  
  attr_accessible :subject, :content
end
