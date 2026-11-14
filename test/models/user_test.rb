require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    assert_equal "downcased@example.com", User.new(email_address: " DOWNCASED@EXAMPLE.COM ").email_address
  end

  test "admin has every permission" do
    User::PERMISSIONS.each { |permission| assert users(:admin).public_send(:"can_#{permission}?") }
  end

  test "permissions come from flags" do
    advisor = users(:advisor)
    assert advisor.can_manage_orders?
    assert_not advisor.can_manage_catalog?
    assert_not advisor.can_delete_records?
  end

  test "inactive user has no permissions" do
    assert_not users(:disabled).can_manage_orders?
  end
end
