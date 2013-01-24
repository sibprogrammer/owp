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

  attr_accessible :login, :password, :password_confirmation, :email, :contact_name, :enabled, :role_id
  attr_accessor :password, :password_confirmation, :current_password

  has_many :virtual_servers
  has_many :requests
  has_many :comments
  belongs_to :role
  delegate :permissions, :to => :role

  before_destroy { |record| record.login != 'admin' }
  after_destroy { |record| EventLog.info("user.removed", { :login => record.login }) }
  after_create { |record| EventLog.info("user.created", { :login => record.login }) }
  after_update { |record| EventLog.info("user.updated", { :login => record.login }) }

  def self.authenticate(login, password)
    return nil if login.blank? || password.blank?
    u = find_by_login(login.downcase)
    u && u.auth?(password) ? u : nil
  end

  def auth?(password)
    if AppConfig.ldap.enabled
      require 'net/ldap'
      ldap = Net::LDAP.new :host => AppConfig.ldap.host
      ldap.auth AppConfig.ldap.login_pattern.sub('<login>', login), password
      ldap.bind || authenticated?(password)
    else
      authenticated?(password)
    end
  end

  def login=(value)
    write_attribute :login, (value ? value.downcase : nil)
  end

  def superadmin?
    can_manage_hardware_servers?
  end

  def password_required?
    external_auth = AppConfig.ldap.enabled
    !external_auth && (crypted_password.blank? || !password.blank?)
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

  def enable
    self.enabled = true
    EventLog.info("user.enabled", { :login => login })
    save
  end

  def disable
    self.enabled = false
    EventLog.info("user.disabled", { :login => login })
    save
  end

  def limit_reached?(limit_name, usage)
    allowed = role.send(limit_name)
    return false if -1 == allowed
    allowed <= usage
  end

  def ip_restriction?(remote_ip)
    allowed_ips = AppConfig.ip_restriction.admin_ips
    return false if !superadmin? or allowed_ips.blank?
    allowed_ips.split(/[\s,;]+/).each do |ip|
      return false if remote_ip == ip
    end
    true
  end

  private

    def matches_dynamic_perm_check?(method_id)
      /^can_([a-zA-Z]\w*)\?$/.match(method_id.to_s)
    end

end
