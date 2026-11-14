require "test_helper"

class CatalogControllerTest < ActionDispatch::IntegrationTest
  test "everyone sees the catalog, only catalog managers change it" do
    sign_in_as users(:advisor)
    get services_path
    assert_select "td", text: "Замена масла"
    get parts_path
    assert_response :success
    assert_no_difference(-> { Service.count }) { post services_path, params: { service: { name: "X", price: 1 } } }
  end

  test "admin manages services and receives parts" do
    sign_in_as users(:admin)
    assert_difference(-> { Service.count }) { post services_path, params: { service: { name: "Мойка", price: 500 } } }
    assert_difference(-> { parts(:filter).reload.quantity }, 10) { patch receive_part_path(parts(:filter)), params: { amount: 10 } }
  end

  test "editing a part does not overwrite stock" do
    sign_in_as users(:admin)
    patch part_path(parts(:oil)), params: { part: { name: "Масло", quantity: 999 } }
    assert_equal 10, parts(:oil).reload.quantity
  end

  test "low stock filter" do
    sign_in_as users(:viewer)
    get parts_path(status: "low")
    assert_select "td", text: "Фильтр масляный"
    assert_select "td", text: "Масло 5W-30", count: 0
  end
end
