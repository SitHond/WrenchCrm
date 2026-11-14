require "test_helper"

class ClientsLoyaltyControllerTest < ActionDispatch::IntegrationTest
  test "admin sets up tiers and sources, client card shows the discount" do
    sign_in_as users(:admin)
    post loyalty_tiers_path, params: { loyalty_tier: { threshold: 5000, labor_percent: 5, parts_percent: 2 } }
    post ad_sources_path, params: { ad_source: { name: "Авито" } }
    source = AdSource.find_by!(name: "Авито")
    patch client_path(clients(:petrov)), params: { client: { discount_mode: "accumulative", ad_source_id: source.id } }
    get client_path(clients(:petrov))
    assert_match "Накопительная", response.body
    assert_match "Авито", response.body
    get clients_path(ad_source_id: source.id)
    assert_select "a", text: "Петров Алексей"
    get work_orders_path(ad_source_id: source.id)
    assert_response :success
    get sources_reports_path
    assert_response :success
  end
end
