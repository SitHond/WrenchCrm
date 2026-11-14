require "test_helper"

class OrderLineTest < ActiveSupport::TestCase
  test "labor line copies name and price from service" do
    line = work_orders(:open_order).labor_lines.create!(service: services(:oil_change))
    assert_equal "Замена масла", line.name
    assert_equal 1200, line.price
  end

  test "custom price wins over catalog price" do
    line = work_orders(:open_order).labor_lines.create!(service: services(:oil_change), price: 900, quantity: 2)
    assert_equal 1800, line.total
  end

  test "part line moves stock on create, update and destroy" do
    part = parts(:oil)
    order = work_orders(:open_order)
    line = nil
    assert_difference(-> { part.reload.quantity }, -2) { line = order.part_lines.create!(part: part, quantity: 2) }
    assert_equal 3800, line.price
    assert_difference(-> { part.reload.quantity }, -1) { line.update!(quantity: 3) }
    assert_difference(-> { part.reload.quantity }, 3) { line.destroy }
  end

  test "closed order rejects new lines" do
    line = work_orders(:closed_order).labor_lines.new(name: "Мойка", price: 500)
    assert_not line.valid?
  end
end
