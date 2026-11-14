require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "shows open orders and low stock in both locales" do
    sign_in_as users(:viewer)
    get root_path
    assert_response :success
    assert_select ".stat-label", text: "В работе"
    assert_match "Фильтр масляный", response.body

    users(:viewer).update!(locale: "en")
    get root_path
    assert_select "h1", text: "Dashboard"
  end
end
