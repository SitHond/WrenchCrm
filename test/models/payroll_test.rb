require "test_helper"

class PayrollTest < ActiveSupport::TestCase
  setup do
    @mechanic = employees(:ivan)
    @mechanic.update!(monthly_salary: 20_000, labor_percent: 40)
    @month = Date.current.beginning_of_month
  end

  def close_order_with_labor(price:, discount: 0)
    order = WorkOrder.create!(vehicle: vehicles(:polo), discount_percent: discount)
    order.labor_lines.create!(name: "Работа", price: price, employee: @mechanic)
    order.change_status!(:in_progress)
    order.change_status!(:ready)
    order.change_status!(:closed)
    order
  end

  test "salary plus labor share after discount plus adjustments" do
    close_order_with_labor(price: 10_000, discount: 10)
    PayrollAdjustment.create!(employee: @mechanic, period: @month, amount: 1000, comment: "Премия")
    payroll = Payroll.new(@mechanic, @month)
    assert_equal 9000, payroll.labor_base
    assert_equal 3600, payroll.labor_pay
    assert_equal 24_600, payroll.accrued
  end

  test "advisor gets a share of handled orders" do
    advisor = Employee.create!(name: "Марина", position: :service_advisor, order_percent: 5)
    order = WorkOrder.create!(vehicle: vehicles(:polo), advisor: advisor)
    order.labor_lines.create!(name: "Работа", price: 2000)
    order.change_status!(:in_progress)
    order.change_status!(:ready)
    order.change_status!(:closed)
    assert_equal 90, Payroll.new(advisor, @month).orders_pay, "5% of 2000 minus 10% client discount"
  end

  test "open orders and other months are not counted" do
    WorkOrder.create!(vehicle: vehicles(:polo)).labor_lines.create!(name: "Работа", price: 5000, employee: @mechanic)
    assert_equal 0, Payroll.new(@mechanic, @month).labor_base
    close_order_with_labor(price: 1000)
    assert_equal 0, Payroll.new(@mechanic, @month.prev_month).labor_base
  end

  test "payouts reduce what is due and leave the cash desk" do
    payout = SalaryPayout.create!(employee: @mechanic, amount: 15_000, period: @month, cash_account: cash_accounts(:cash))
    assert_equal 5000, Payroll.new(@mechanic, @month).due
    assert_equal(-15_000, cash_accounts(:cash).balance)
    assert payout.cash_operation.salary?
  end
end
