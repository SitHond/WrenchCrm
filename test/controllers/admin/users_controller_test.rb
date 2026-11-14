require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  test "admin creates a user with permissions" do
    sign_in_as users(:admin)
    assert_difference(-> { User.count }) do
      post admin_users_path, params: { user: { name: "Пастор", email_address: "pastor@example.com", password: "secret123",
                                               password_confirmation: "secret123", locale: "ru", manage_groups: "1" } }
    end
    assert User.find_by!(email_address: "pastor@example.com").can_manage_groups?
  end

  test "blank password keeps the old one" do
    sign_in_as users(:admin)
    patch admin_user_path(users(:viewer)), params: { user: { name: "Зритель", password: "" } }
    assert users(:viewer).reload.authenticate("password")
    assert_equal "Зритель", users(:viewer).name
  end

  test "admin cannot remove own admin flag or delete self" do
    admin = users(:admin)
    sign_in_as admin
    patch admin_user_path(admin), params: { user: { admin: "0" } }
    assert admin.reload.admin?
    assert_no_difference(-> { User.count }) { delete admin_user_path(admin) }
  end

  test "non-admin is denied" do
    sign_in_as users(:editor)
    get admin_users_path
    assert_redirected_to root_path
  end
end
