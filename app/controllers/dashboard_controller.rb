class DashboardController < ApplicationController
  def show
    @status_counts = WorkOrder.unfinished.group(:status).count
    @ready_orders = WorkOrder.ready.includes(:client, :vehicle).order(:completed_at).limit(10)
    @due_orders = WorkOrder.unfinished.where(promised_at: ..Date.current.end_of_day).includes(:client, :vehicle).order(:promised_at).limit(10)
    @revenue_month = Payment.in_period(Date.current.all_month).sum(:amount)
    @revenue_today = Payment.in_period(Date.current.all_day).sum(:amount)
    @orders_month = WorkOrder.where(created_at: Date.current.all_month).count
    @appointments_today = Appointment.on_day(Date.current).busy.includes(:client, :vehicle, :bay).chronological
    @low_stock = Part.low_stock.ordered.limit(10)
  end
end
