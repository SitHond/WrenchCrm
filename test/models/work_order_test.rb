require "test_helper"

class WorkOrderTest < ActiveSupport::TestCase
  test "new order takes client, mileage and discount from the vehicle" do
    order = WorkOrder.create!(vehicle: vehicles(:polo))
    assert_equal clients(:taxi), order.client
    assert_equal 10, order.discount_percent
    assert order.accepted?
  end

  test "vehicle must belong to client" do
    order = WorkOrder.new(vehicle: vehicles(:polo), client: clients(:petrov))
    assert_not order.valid?
  end

  test "totals with discount and payments" do
    order = work_orders(:open_order)
    order.update!(discount_percent: 10)
    assert_equal 1500, order.labor_total
    assert_equal 3800, order.parts_total
    assert_equal 530, order.discount_amount
    assert_equal 4770, order.total
    order.payments.create!(amount: 1000, payment_method: :cash)
    assert_equal 3770, order.reload.balance
  end

  test "mileage updates the vehicle" do
    work_orders(:open_order).update!(mileage: 91_000)
    assert_equal 91_000, vehicles(:solaris).reload.mileage
  end

  test "status transitions" do
    order = work_orders(:open_order)
    assert_raises(ArgumentError) { order.change_status!(:closed) }
    order.change_status!(:ready)
    assert order.completed_at
    order.change_status!(:closed)
    assert order.closed_at
    assert_not order.editable?
  end

  test "cancelling returns parts to stock" do
    assert_difference -> { parts(:oil).reload.quantity }, 1 do
      work_orders(:open_order).change_status!(:cancelled)
    end
  end

  test "search by number, plate and client" do
    order = work_orders(:open_order)
    assert_includes WorkOrder.search(order.number), order
    assert_includes WorkOrder.search("А123"), order
    assert_includes WorkOrder.search("Петров"), order
  end
end
