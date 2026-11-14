module Report
  # Parts sold through closed work orders and counter sales, with margin.
  class Parts
    Row = Struct.new(:name, :quantity, :revenue, :cost) do
      def margin = revenue - cost
      def margin_percent = revenue.zero? ? 0 : (margin / revenue * 100).round(1)
    end

    attr_reader :range

    def initialize(range)
      @range = range
    end

    def rows
      @rows ||= begin
        rows = Hash.new { |hash, name| hash[name] = Row.new(name, 0, 0, 0) }
        names = Part.pluck(:id, :name).to_h
        (order_lines + sale_lines).each do |part_id, name, qty, revenue, cost|
          label = names[part_id] || name
          add(rows[label], qty, revenue, cost)
        end
        rows.values.sort_by { |row| -row.revenue }
      end
    end

    def revenue = rows.sum(&:revenue)
    def cost = rows.sum(&:cost)
    def margin = revenue - cost

    private
      def add(row, quantity, revenue, cost)
        row.quantity += quantity.to_d
        row.revenue += revenue.to_d
        row.cost += cost.to_d
      end

      def order_lines
        WorkOrderPart.joins(:work_order).where(client_supplied: false, work_orders: { status: WorkOrder.statuses[:closed], closed_at: range })
          .group(:part_id, :name).pluck(:part_id, :name, Arel.sql("SUM(work_order_parts.quantity)"),
                              Arel.sql("SUM(work_order_parts.quantity * work_order_parts.price * (1 - work_orders.parts_discount_percent / 100))"),
                              Arel.sql("SUM(work_order_parts.quantity * work_order_parts.cost)"))
      end

      def sale_lines
        SaleLine.joins(:sale).where(sales: { sold_at: range })
          .group(:part_id, :name).pluck(:part_id, :name, Arel.sql("SUM(sale_lines.quantity)"),
                              Arel.sql("SUM(sale_lines.quantity * sale_lines.price * (1 - sales.discount_percent / 100))"),
                              Arel.sql("SUM(sale_lines.quantity * sale_lines.cost)"))
      end
  end
end
