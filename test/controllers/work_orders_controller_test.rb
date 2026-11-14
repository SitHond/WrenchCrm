require "test_helper"

class WorkOrdersControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:advisor) }

  test "full flow: create, add lines, finish, pay, close" do
    post work_orders_path, params: { work_order: { vehicle_id: vehicles(:polo).id, complaint: "Стук", mileage: 1000 } }
    order = WorkOrder.last
    assert_redirected_to work_order_path(order)
    assert_equal clients(:taxi), order.client

    post work_order_work_order_labors_path(order), params: { work_order_labor: { service_id: services(:oil_change).id, quantity: 1 } }
    post work_order_work_order_parts_path(order), params: { work_order_part: { part_id: parts(:oil).id, quantity: 1 } }
    assert_equal 1200 + 3800, order.reload.subtotal

    patch status_work_order_path(order, status: "in_progress")
    patch status_work_order_path(order, status: "ready")
    assert order.reload.ready?

    post work_order_payments_path(order), params: { payment: { amount: order.total, payment_method: "card" } }
    assert order.reload.balance.zero?

    patch status_work_order_path(order, status: "closed")
    assert order.reload.closed?

    get work_order_path(order)
    assert_response :success
    get print_work_order_path(order)
    assert_response :success
    assert_match "Замена масла", response.body
  end

  test "invalid transition is rejected" do
    patch status_work_order_path(work_orders(:open_order), status: "closed")
    assert_equal I18n.t("work_orders.invalid_transition"), flash[:alert]
    assert work_orders(:open_order).reload.in_progress?
  end

  test "line quantity update and removal" do
    line = work_order_parts(:oil_line)
    patch work_order_work_order_part_path(work_orders(:open_order), line), params: { work_order_part: { quantity: 2 } }
    assert_equal 2, line.reload.quantity
    delete work_order_work_order_part_path(work_orders(:open_order), line)
    assert_not WorkOrderPart.exists?(line.id)
  end

  test "closed order lines cannot be added" do
    assert_no_difference(-> { WorkOrderLabor.count }) do
      post work_order_work_order_labors_path(work_orders(:closed_order)), params: { work_order_labor: { name: "X", price: 1 } }
    end
  end

  test "index filters by status" do
    get work_orders_path
    assert_select "a", text: work_orders(:open_order).number
    assert_select "a", text: work_orders(:closed_order).number, count: 0
    get work_orders_path(status: "all")
    assert_select "a", text: work_orders(:closed_order).number
  end

  test "viewer cannot create orders or take payments" do
    sign_in_as users(:viewer)
    assert_no_difference(-> { WorkOrder.count }) do
      post work_orders_path, params: { work_order: { vehicle_id: vehicles(:polo).id } }
    end
    assert_no_difference(-> { Payment.count }) do
      post work_order_payments_path(work_orders(:open_order)), params: { payment: { amount: 100 } }
    end
  end
end
