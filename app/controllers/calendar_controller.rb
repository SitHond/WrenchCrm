class CalendarController < ApplicationController
  def show
    @month = begin
      Date.iso8601("#{params[:month]}-01")
    rescue Date::Error
      Date.current.beginning_of_month
    end
    @days = (@month.beginning_of_week..@month.end_of_month.end_of_week).to_a
    range = @days.first.in_time_zone.beginning_of_day..@days.last.in_time_zone.end_of_day
    @appointments = Appointment.busy.where(starts_at: range).includes(:vehicle, :bay).chronological.group_by { |a| a.starts_at.to_date }
    @due_orders = WorkOrder.unfinished.where(promised_at: range).includes(:vehicle).order(:promised_at).group_by { |o| o.promised_at.to_date }
    @closed_orders = WorkOrder.closed.where(closed_at: range).group("DATE(closed_at AT TIME ZONE 'UTC' AT TIME ZONE '#{Time.zone.tzinfo.name}')").count
  end
end
