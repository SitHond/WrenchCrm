module Report
  # Labor in work orders closed during the period, by service and by employee.
  class Labor
    attr_reader :range

    def initialize(range)
      @range = range
    end

    def lines
      WorkOrderLabor.joins(:work_order).where(work_orders: { status: WorkOrder.statuses[:closed], closed_at: range })
    end

    def by_service
      lines.group(:name).pluck(:name, Arel.sql("COUNT(*)"), Arel.sql("SUM(work_order_labors.quantity)"),
                               Arel.sql("SUM(work_order_labors.quantity * work_order_labors.price)"))
        .sort_by { |row| -row[3].to_d }
    end

    def by_employee
      names = Employee.pluck(:id, :name).to_h
      lines.left_joins(:performers).group("work_order_labor_performers.employee_id")
        .pluck(Arel.sql("work_order_labor_performers.employee_id"), Arel.sql("COUNT(DISTINCT work_order_id)"),
               Arel.sql("SUM(work_order_labors.quantity * COALESCE(work_order_labor_performers.share, 100) / 100)"),
               Arel.sql("SUM(work_order_labors.quantity * work_order_labors.price * COALESCE(work_order_labor_performers.share, 100) / 100)"))
        .map { |id, orders, hours, sum| [ names[id], orders, hours, sum ] }
        .sort_by { |row| -row[3].to_d }
    end

    def total
      lines.sum("work_order_labors.quantity * work_order_labors.price")
    end
  end
end
