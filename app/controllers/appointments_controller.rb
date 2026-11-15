class AppointmentsController < ApplicationController
  before_action :set_appointment, only: %i[ show edit update destroy status check_in ]
  require_permission :manage_orders, except: %i[ index show ]

  def index
    @date = parse_date(params[:date]) || Date.current
    @bays = Bay.active.ordered.to_a
    @appointments = Appointment.on_day(@date).where.not(status: :cancelled)
      .includes(:client, :vehicle, :mechanic, :bay).chronological
  end

  def show
  end

  def new
    vehicle = Vehicle.find_by(id: params[:vehicle_id])
    @appointment = Appointment.new(
      vehicle: vehicle,
      bay_id: params[:bay_id],
      mechanic_id: params[:mechanic_id],
      starts_at: parse_time(params[:starts_at]) || next_slot,
      duration_minutes: 60,
      description: ServiceReminder.find_by(id: params[:service_reminder_id])&.title
    )
  end

  def create
    @appointment = Appointment.new(appointment_params)
    if @appointment.save
      ServiceReminder.where(id: params[:service_reminder_id], vehicle_id: @appointment.vehicle_id).update_all(status: ServiceReminder.statuses[:booked])
      redirect_to appointments_path(date: @appointment.starts_at.to_date), notice: t("flash.created", model: Appointment.model_name.human)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @appointment.duration_minutes = @appointment.duration
  end

  def update
    if @appointment.update(appointment_params)
      redirect_to appointments_path(date: @appointment.starts_at.to_date), notice: t("flash.updated", model: Appointment.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def status
    @appointment.change_status!(params.expect(:status))
    redirect_to @appointment, notice: t("appointments.status_changed", status: helpers.enum_label(Appointment, :status, @appointment.status))
  rescue ArgumentError, ActiveRecord::RecordInvalid
    redirect_to @appointment, alert: t("appointments.status_failed")
  end

  def check_in
    work_order = @appointment.check_in!
    redirect_to work_order, notice: t("appointments.checked_in")
  rescue ArgumentError
    redirect_to @appointment, alert: t("appointments.status_failed")
  end

  def destroy
    date = @appointment.starts_at.to_date
    @appointment.destroy
    redirect_to appointments_path(date: date), notice: t("flash.destroyed", model: Appointment.model_name.human), status: :see_other
  end

  private
    def set_appointment
      @appointment = Appointment.find(params[:id])
    end

    def appointment_params
      permitted = params.expect(appointment: [ :vehicle_id, :bay_id, :mechanic_id, :date, :time, :duration_minutes, :description ])
      date = parse_date(permitted.delete(:date))
      time = permitted.delete(:time)
      permitted[:starts_at] = Time.zone.parse("#{date} #{time}") if date && time.present?
      permitted
    end

    def parse_date(value)
      Date.iso8601(value.to_s)
    rescue Date::Error
      nil
    end

    def parse_time(value)
      Time.zone.iso8601(value.to_s)
    rescue ArgumentError
      nil
    end

    def next_slot
      hours = Rails.configuration.x.workday_hours
      slot = Time.current.beginning_of_hour + 1.hour
      slot.hour.in?(hours) ? slot : Date.tomorrow.in_time_zone.change(hour: hours.first)
    end
end
