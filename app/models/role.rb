class Role < ActiveRecord::Base
  has_and_belongs_to_many :permissions
  has_many :users

  validates_uniqueness_of :name

  attr_accessible :name, :limit_backups

  validates_numericality_of :limit_backups, :only_integer => true

  before_destroy { |record| 0 == record.users.count && !record.built_in }
  after_destroy { |record| EventLog.info("role.removed", { :name => record.name }) }

  def display_name
    case name
      when 'superadmin' then I18n.translate('admin.users.role.infrastructure_admin')
      when 've_admin' then I18n.translate('admin.users.role.virtual_server_owner')
      else name
    end
  end

  def limit_backups=(value)
    write_attribute :limit_backups, (value.to_i.to_s != value.to_s ? -1 : value)
  end

end
