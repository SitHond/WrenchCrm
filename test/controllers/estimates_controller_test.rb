require "test_helper"

class EstimatesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:advisor) }

  test "create an estimate, print it and approve it" do
    get new_work_order_path(estimate: 1)
    assert_select "h1", text: "Новая смета"
    post work_orders_path, params: { work_order: { vehicle_id: vehicles(:polo).id, status: "estimate", complaint: "Стук" } }
    estimate = WorkOrder.last
    assert estimate.estimate?
    get work_order_path(estimate)
    assert_match "Клиент согласовал", response.body
    get print_work_order_path(estimate)
    assert_match "Предварительная смета", response.body
    patch status_work_order_path(estimate, status: "accepted")
    assert estimate.reload.accepted?
  end

  test "status param cannot skip to closed on create" do
    post work_orders_path, params: { work_order: { vehicle_id: vehicles(:polo).id, status: "closed" } }
    assert WorkOrder.last.accepted?
  end

  test "shortage shows a clear message" do
    ShopSetting.current.update!(allow_negative_stock: false)
    estimate = WorkOrder.create!(vehicle: vehicles(:polo), status: :estimate)
    estimate.part_lines.create!(part: parts(:filter), quantity: 5)
    patch status_work_order_path(estimate, status: "accepted")
    assert_match "Фильтр масляный", flash[:alert]
  end
end
