require "test_helper"

class MarkupTest < ActiveSupport::TestCase
  setup do
    MarkupRule.create!(cost_from: 0, percent: 80)
    MarkupRule.create!(cost_from: 500, percent: 50)
  end

  test "price from the matching range, rounded up to 10" do
    assert_equal 900, MarkupRule.price_for(499)
    assert_equal 750, MarkupRule.price_for(500)
    assert_nil MarkupRule.price_for(0)
  end

  test "auto-priced part follows the cost on receipt" do
    part = parts(:filter)
    part.update!(auto_price: true)
    assert_equal 750, part.price, "cost is zero, so the current price stays"
    receipt = suppliers(:autodetal).purchase_receipts.create!
    receipt.lines.create!(part: part, quantity: 1, cost: 400)
    receipt.post!
    assert_equal 200, part.reload.cost, "average of 1 at 0 and 1 at 400"
    assert_equal 360, part.price
  end

  test "manual price stays when auto pricing is off" do
    parts(:oil).update!(cost: 5000)
    assert_equal 3800, parts(:oil).reload.price
  end

  test "reorder suggests restocking to twice the minimum" do
    row = Report::Reorder.new.rows.find { |r| r.part == parts(:filter) }
    assert_equal 9, row.suggested
  end
end
