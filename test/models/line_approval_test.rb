require "test_helper"

class LineApprovalTest < ActiveSupport::TestCase
  setup do
    Current.session = users(:advisor).sessions.create!
    @order = work_orders(:open_order) # in progress
  end

  test "lines added at intake are pre-agreed, later ones wait for the customer" do
    intake = WorkOrder.create!(vehicle: vehicles(:polo))
    assert intake.labor_lines.create!(name: "Диагностика", price: 1000).approved?

    extra = @order.labor_lines.create!(name: "Замена ШРУС", price: 5000)
    assert_not extra.approved?
    assert_equal 1500, @order.reload.labor_total, "extra work stays out of the total"
    assert_equal 5000, @order.pending_total
  end

  test "approval records method, user and note; then the line counts" do
    extra = @order.labor_lines.create!(name: "Замена ШРУС", price: 5000)
    extra.approve!(method: :phone, note: "Клиент согласен")
    extra.reload
    assert extra.approved_phone?
    assert_equal users(:advisor), extra.approved_by
    assert_equal 6500, @order.reload.labor_total
  end

  test "an order with unapproved lines cannot be finished" do
    @order.part_lines.create!(part: parts(:filter), quantity: 1)
    assert_raises(WorkOrder::PendingApproval) { @order.change_status!(:ready) }
    @order.part_lines.reload.each { |line| line.approve!(method: :in_person) unless line.approved? }
    @order.reload.change_status!(:ready)
    assert @order.ready?
  end

  test "estimate lines are agreed when the estimate is" do
    estimate = WorkOrder.create!(vehicle: vehicles(:polo), status: :estimate)
    line = estimate.labor_lines.create!(name: "Ремонт", price: 100)
    assert line.approved?
  end
end
