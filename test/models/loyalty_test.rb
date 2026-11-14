require "test_helper"

class LoyaltyTest < ActiveSupport::TestCase
  setup do
    LoyaltyTier.create!(threshold: 10_000, labor_percent: 5, parts_percent: 3)
    LoyaltyTier.create!(threshold: 50_000, labor_percent: 10, parts_percent: 5)
    @client = clients(:petrov)
    @client.update!(discount_mode: :accumulative)
  end

  test "discount follows the amount paid" do
    assert_equal 0, @client.labor_discount
    work_orders(:open_order).payments.create!(amount: 12_000, payment_method: :cash)
    assert_equal 12_000, @client.total_spent
    assert_equal 5, @client.labor_discount
    assert_equal 3, @client.parts_discount
  end

  test "sales count towards the total" do
    Sale.create!(client: @client, payment_method: :cash, lines_attributes: [ { part_id: parts(:oil).id, quantity: 3 } ])
    assert_equal 11_400, @client.total_spent
  end

  test "new work order takes the accumulative discounts" do
    work_orders(:open_order).payments.create!(amount: 60_000, payment_method: :card)
    order = WorkOrder.create!(vehicle: vehicles(:solaris))
    assert_equal 10, order.labor_discount_percent
    assert_equal 5, order.parts_discount_percent
  end

  test "fixed mode keeps the manual percent" do
    clients(:taxi).update!(discount_mode: :fixed)
    assert_equal 10, clients(:taxi).labor_discount
    assert_equal 10, clients(:taxi).parts_discount
  end
end
