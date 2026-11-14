require "test_helper"

class StockTest < ActiveSupport::TestCase
  test "every stock change is logged" do
    part = parts(:oil)
    assert_difference -> { part.stock_movements.count }, 3 do
      part.adjust_stock!(5, kind: :manual)
      part.adjust_stock!(-1, kind: :write_off, comment: "Разбили")
      part.set_quantity!(12)
    end
    assert_equal 12, part.reload.quantity
    assert_equal %w[manual write_off inventory], part.stock_movements.order(:id).last(3).map(&:kind)
  end

  test "posting a receipt adds stock and averages the cost" do
    receipt = suppliers(:autodetal).purchase_receipts.create!(number: "1")
    receipt.lines.create!(part: parts(:oil), quantity: 10, cost: 3100)
    receipt.post!
    part = parts(:oil).reload
    assert_equal 20, part.quantity
    assert_equal 3000, part.cost, "(10 × 2900 + 10 × 3100) / 20"
    assert receipt.posted?
    assert_raises(ArgumentError) { receipt.post! }
    assert_not receipt.lines.new(part: parts(:filter), quantity: 1, cost: 1).valid?
  end

  test "empty receipt cannot be posted" do
    assert_raises(ArgumentError) { suppliers(:autodetal).purchase_receipts.create!.post! }
  end

  test "supplier debt is purchases minus payments" do
    supplier = suppliers(:autodetal)
    receipt = supplier.purchase_receipts.create!
    receipt.lines.create!(part: parts(:oil), quantity: 2, cost: 1000)
    receipt.post!
    CashOperation.create!(kind: :supplier_payment, supplier: supplier, cash_account: cash_accounts(:bank), amount: -500)
    assert_equal 1500, supplier.debt
  end

  test "work order part line remembers its cost" do
    line = work_orders(:open_order).part_lines.create!(part: parts(:oil), quantity: 1)
    assert_equal 2900, line.cost
    assert_equal 900, line.margin
  end

  test "analogs are symmetric" do
    PartAnalog.link!(parts(:oil), parts(:filter))
    PartAnalog.link!(parts(:filter), parts(:oil))
    assert_equal 1, PartAnalog.count
    assert_includes parts(:filter).all_analogs, parts(:oil)
    PartAnalog.unlink!(parts(:filter), parts(:oil))
    assert_empty parts(:oil).all_analogs
  end
end
