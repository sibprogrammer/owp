class DefaultAdmin < ActiveRecord::Migration
  def self.up
    user = User.new
    user.login = 'admin'
    user.password = 'admin'
    user.password_confirmation = 'admin'
    user.save(false)
  end

  def self.down
    user = User.find_by_login('admin')
    user.destroy
  end
end
