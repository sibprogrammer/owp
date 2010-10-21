class Role < ActiveRecord::Base
  has_and_belongs_to_many :permissions
  has_many :users
  
  validates_uniqueness_of :name
  
  attr_accessible :name
  
  def display_name
    case name
      when 'superadmin' then I18n.translate('admin.users.role.infrastructure_admin')
      when 've_admin' then I18n.translate('admin.users.role.virtual_server_owner')
      else name
    end
  end
  
  protected
  
    def before_destroy
      0 == role.users.count && !role.built_in
    end
  
end
