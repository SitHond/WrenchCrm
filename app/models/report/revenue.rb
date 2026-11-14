module Report
  # Money received and orders closed in a period.
  class Revenue
    attr_reader :range

    def initialize(range)
      @range = range
    end

    def operations
      CashOperation.in_period(range).where.not(kind: :transfer)
    end

    def income
      operations.incoming.sum(:amount)
    end

    def expenses
      -operations.outgoing.sum(:amount)
    end

    def profit
      income - expenses
    end

    def income_by_kind
      operations.incoming.group(:kind).sum(:amount)
    end

    def expenses_by_kind
      operations.outgoing.group(:kind).sum(:amount).transform_values(&:abs)
    end

    def closed_orders
      @closed_orders ||= WorkOrder.closed.where(closed_at: range).includes(:labor_lines, :part_lines).to_a
    end

    def orders_total
      closed_orders.sum(&:total)
    end

    def average_check
      closed_orders.empty? ? 0 : (orders_total / closed_orders.size).round(2)
    end

    def sales
      @sales ||= Sale.in_period(range).includes(:lines).to_a
    end

    def daily_income
      operations.incoming.group("DATE(occurred_at AT TIME ZONE 'UTC' AT TIME ZONE '#{Time.zone.tzinfo.name}')").sum(:amount).sort.to_h
    end
  end
end
