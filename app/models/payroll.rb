# Monthly pay for one employee: salary + share of their labor + share of orders they handled as advisor.
class Payroll
  attr_reader :employee, :period

  def self.for_month(month)
    Employee.active.ordered.map { |employee| new(employee, month) }
  end

  def initialize(employee, month)
    @employee = employee
    @period = month.to_date.beginning_of_month
  end

  def range
    period.in_time_zone.all_month
  end

  def labor_lines
    @labor_lines ||= WorkOrderLabor.joins(:work_order).includes(:work_order)
      .where(employee: employee, work_orders: { status: WorkOrder.statuses[:closed], closed_at: range })
      .order("work_orders.closed_at")
  end

  # Labor amount after the order discount.
  def labor_base
    labor_lines.sum { |line| line.total * (1 - line.work_order.discount_percent / 100) }.round(2)
  end

  def advised_orders
    @advised_orders ||= WorkOrder.closed.where(advisor: employee, closed_at: range)
      .includes(:labor_lines, :part_lines).order(:closed_at)
  end

  def orders_base
    advised_orders.sum(&:total)
  end

  def labor_pay
    (labor_base * employee.labor_percent / 100).round(2)
  end

  def orders_pay
    (orders_base * employee.order_percent / 100).round(2)
  end

  def adjustments
    @adjustments ||= employee.payroll_adjustments.where(period: period).order(:created_at)
  end

  def adjustments_total
    adjustments.sum(&:amount)
  end

  def accrued
    employee.monthly_salary + labor_pay + orders_pay + adjustments_total
  end

  def payouts
    @payouts ||= employee.salary_payouts.where(period: period).includes(:cash_account).order(:paid_on)
  end

  def paid
    payouts.sum(&:amount)
  end

  def due
    accrued - paid
  end
end
