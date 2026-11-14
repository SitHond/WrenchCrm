require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:viewer) }

  test "changes locale" do
    patch profile_path, params: { user: { name: "Viewer", locale: "en" } }
    assert_equal "en", users(:viewer).reload.locale
    get root_path
    assert_select "html[lang=en]"
  end

  test "password change requires current password" do
    patch profile_path, params: { user: { password: "newpass123", password_confirmation: "newpass123", password_challenge: "wrong" } }
    assert_response :unprocessable_entity
    patch profile_path, params: { user: { password: "newpass123", password_confirmation: "newpass123", password_challenge: "password" } }
    assert users(:viewer).reload.authenticate("newpass123")
  end
end
