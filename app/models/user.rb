require 'digest/sha1'

class User < ActiveRecord::Base
  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken

  validates_presence_of :login
  validates_length_of :login, :within => 2..40
  validates_uniqueness_of :login
  validates_format_of :login, :with => Authentication.login_regex, :message => Authentication.bad_login_message
  validates_format_of :email, :with => /^.+@.+$/, :if => :email?

  attr_accessible :login, :password, :password_confirmation, :email, :contact_name,
    :enabled, :role_id
  
  attr_accessor :password, :password_confirmation, :current_password
  
  has_many :virtual_servers
  has_many :requests
  has_many :comments
  belongs_to :role
  delegate :permissions, :to => :role

  def self.authenticate(login, password)
    return nil if login.blank? || password.blank?
    u = find_by_login(login.downcase) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  def login=(value)
    write_attribute :login, (value ? value.downcase : nil)
  end
  
  def superadmin?
    can_manage_hardware_servers?
  end
  
  def can_control(server)
    superadmin? or (server.user and (server.user.id == self.id))
  end
  
  def full_name
    contact_name.blank? ? login : "#{contact_name} (#{login})"
  end
  
  def method_missing(method_id, *args)
    if match = matches_dynamic_perm_check?(method_id)
      return true if permissions.find_by_name(match.captures.first)
    else
      super
    end
  end

  protected
  
    def before_destroy
      login != 'admin'
    end
    
  private
  
    def matches_dynamic_perm_check?(method_id)
      /^can_([a-zA-Z]\w*)\?$/.match(method_id.to_s)
    end
end
