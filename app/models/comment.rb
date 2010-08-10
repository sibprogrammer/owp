class Comment < ActiveRecord::Base
  belongs_to :request
  belongs_to :user

  validates_presence_of :content
  
  attr_accessible :content
end
