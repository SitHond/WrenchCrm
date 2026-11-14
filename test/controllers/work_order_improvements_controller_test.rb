require "test_helper"

class WorkOrderImprovementsControllerTest < ActionDispatch::IntegrationTest
  test "add and remove a performer" do
    sign_in_as users(:advisor)
    line = work_order_labors(:diag)
    other = Employee.create!(name: "Пётр")
    post work_order_work_order_labor_performers_path(work_orders(:open_order), line), params: { work_order_labor_performer: { employee_id: other.id, share: 40 } }
    assert_equal [ other ], line.reload.employees
    delete work_order_work_order_labor_performer_path(work_orders(:open_order), line, line.performers.first)
    assert_empty line.reload.performers
  end

  test "order page shows split discounts and the client part flag" do
    sign_in_as users(:advisor)
    work_orders(:open_order).update!(labor_discount_percent: 10)
    post work_order_work_order_parts_path(work_orders(:open_order)), params: { work_order_part: { name: "Свой фильтр", quantity: 1, client_supplied: "1" } }
    get work_order_path(work_orders(:open_order))
    assert_match "Скидка на работы 10%", response.body
    assert_select ".badge", text: "Товар клиента"
  end

  test "admin edits shop settings and complexity levels" do
    sign_in_as users(:admin)
    get edit_shop_settings_path
    assert_response :success
    patch shop_settings_path, params: { shop_setting: { legal_name: "ООО «Гайка»", inn: "7701234567", allow_negative_stock: "0" } }
    assert_equal "ООО «Гайка»", ShopSetting.current.legal_name
    assert_not ShopSetting.current.allow_negative_stock
    post complexity_levels_path, params: { complexity_level: { name: "Кроссовер" } }
    assert ComplexityLevel.exists?(name: "Кроссовер")
  end

  test "service form saves and clears prices by level" do
    sign_in_as users(:admin)
    level = ComplexityLevel.create!(name: "Внедорожник")
    service = services(:oil_change)
    patch service_path(service), params: { service: { prices_attributes: { "0" => { complexity_level_id: level.id, price: "1700" } } } }
    price = service.prices.sole
    assert_equal 1700, price.price
    patch service_path(service), params: { service: { prices_attributes: { "0" => { id: price.id, complexity_level_id: level.id, price: "" } } } }
    assert_empty service.prices.reload
    get edit_service_path(service)
    assert_response :success
  end

  test "settings are admin only" do
    sign_in_as users(:advisor)
    get edit_shop_settings_path
    assert_redirected_to root_path
  end
end
