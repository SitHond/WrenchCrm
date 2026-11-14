module Report
  # Clients, orders and money by advertising source; new clients counted by creation date.
  class Sources
    Row = Struct.new(:name, :new_clients, :orders, :revenue)

    attr_reader :range

    def initialize(range)
      @range = range
    end

    def rows
      names = AdSource.pluck(:id, :name).to_h
      new_clients = Client.where(created_at: range).group(:ad_source_id).count
      orders = WorkOrder.closed.where(closed_at: range).joins(:client).group("clients.ad_source_id").count
      revenue = Payment.where(paid_at: range).joins(work_order: :client).group("clients.ad_source_id").sum(:amount)
      (new_clients.keys | orders.keys | revenue.keys).map do |id|
        Row.new(names[id], new_clients[id].to_i, orders[id].to_i, revenue[id].to_d)
      end.sort_by { |row| -row.revenue }
    end
  end
end
