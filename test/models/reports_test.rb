require "test_helper"

class ReportsTest < ActiveSupport::TestCase
  setup { @range = Date.current.all_month.then { |r| r.first.in_time_zone..r.last.in_time_zone.end_of_day } }

  test "revenue counts money in and out, not transfers" do
    work_orders(:open_order).payments.create!(amount: 5000, payment_method: :cash)
    CashOperation.create!(kind: :expense, cash_account: cash_accounts(:cash), amount: -1000)
    CashOperation.transfer!(from: cash_accounts(:cash), to: cash_accounts(:bank), amount: 2000)
    report = Report::Revenue.new(@range)
    assert_equal 5000, report.income
    assert_equal 1000, report.expenses
    assert_equal 4000, report.profit
  end

  test "parts margin from closed orders and sales" do
    order = work_orders(:open_order)
    order.part_lines.create!(part: parts(:filter), quantity: 1, price: 1000)
    approve_all(order)
    order.change_status!(:ready)
    order.change_status!(:closed)
    Sale.create!(payment_method: :cash, lines_attributes: [ { part_id: parts(:oil).id, quantity: 1 } ])
    report = Report::Parts.new(@range)
    oil = report.rows.find { |row| row.name == parts(:oil).name }
    assert_equal 3800 * 2, oil.revenue, "the fixture line in the closed order and the sale are one row"
    assert_equal 3800 * 2 - 2900, oil.margin, "the fixture line has no cost recorded, the sold one cost 2900"
    assert_equal 3800 * 2 + 1000, report.revenue
  end

  test "labor by employee" do
    order = work_orders(:open_order)
    order.labor_lines.create!(name: "Замена", price: 2000, employee: employees(:ivan))
    approve_all(order)
    order.change_status!(:ready)
    order.change_status!(:closed)
    rows = Report::Labor.new(@range).by_employee
    assert_includes rows.map(&:first), "Иван Кузнецов"
  end
end
