require 'test_helper'

class UserTest < ActiveSupport::TestCase

  test "Admin has superadmin role" do
    admin = users(:admin)
    assert admin.superadmin?
  end

  test "Authenticate user" do
    assert_not_nil User.authenticate('admin', 'monkey')
  end

  test "Fail to authenticate with bad password" do
    assert_nil User.authenticate('admin', 'badpassword')
  end

  test "Fail to authenticate with bad login" do
    assert_nil User.authenticate('badlogin', 'monkey')
  end

  test "Two characters logins are allowed (issue 43)" do
    user = User.new({ :login => 'sp', :password => 'password', :password_confirmation => 'password' })
    assert user.valid?
  end

  test "One character login is not allowed" do
    user = User.new({ :login => 'a', :password => 'password', :password_confirmation => 'password' })
    assert !user.valid?
  end

  test "Admin removal is not allowed" do
    admin = users(:admin)
    assert !admin.destroy
  end

  test "User removal is allowed" do
    user = users(:john)
    assert user.destroy
  end

  test "Logins are always in lowercase" do
    user = User.new({ :login => 'CAPS', :password => 'password', :password_confirmation => 'password' })
    assert_equal "caps", user.login
  end

  test "User can control virtual server" do
    user = users(:john)
    server_101 =  virtual_servers(:server_101)
    server_101.user = user
    assert user.can_control(server_101)
  end

  test "User cannot control foreign virtual server" do
    user = users(:john)
    server_101 =  virtual_servers(:server_101)
    assert !user.can_control(server_101)
  end

  test "Admin can control any virtual server" do
    admin = users(:admin)
    server_101 =  virtual_servers(:server_101)
    assert admin.can_control(server_101)
  end

  test "User can have email" do
    user = User.new({ :login => 'test', :email => 'root@localhost' })
    assert_equal "root@localhost", user.email
  end

  test "Email address should be valid" do
    user = User.new({ :login => 'test', :password => 'password', :password_confirmation => 'password', :email => 'not-email' })
    assert !user.valid?
  end

end
