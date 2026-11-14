require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "shows counts in both locales" do
    sign_in_as users(:viewer)
    get root_path
    assert_response :success
    assert_select ".stat-value", text: "2"

    users(:viewer).update!(locale: "en")
    get root_path
    assert_select "h1", text: "Dashboard"
  end
end
