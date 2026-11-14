require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "admin has every permission" do
    User::PERMISSIONS.each { |permission| assert users(:admin).public_send(:"can_#{permission}?") }
  end

  test "permissions come from flags" do
    editor = users(:editor)
    assert editor.can_add_records?
    assert_not editor.can_delete_records?
    assert_not editor.can_manage_groups?
  end

  test "inactive user has no permissions" do
    assert_not users(:disabled).can_add_records?
  end
end
