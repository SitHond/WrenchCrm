class ServiceRemindersController < ApplicationController
  require_permission :manage_clients, except: :index
  before_action :set_reminder, only: %i[ update destroy contacted snooze ]

  def index
    @reminders = case params[:view]
    when "active" then ServiceReminder.active.includes(vehicle: :client).sort_by { |r| r.expected_on || Date.new(9999) }
    when "closed" then ServiceReminder.where(status: %i[done dismissed]).includes(vehicle: :client).order(updated_at: :desc).limit(100)
    else ServiceReminder.due.sort_by { |r| r.expected_on }
    end
  end

  def create
    vehicle = Vehicle.find(params.dig(:service_reminder, :vehicle_id))
    reminder = vehicle.service_reminders.new(params.expect(service_reminder: [ :title, :due_on, :due_mileage, :service_id ]))
    if reminder.save
      redirect_to vehicle, notice: t("flash.created", model: ServiceReminder.model_name.human)
    else
      redirect_to vehicle, alert: reminder.errors.full_messages.to_sentence
    end
  end

  def update
    @reminder.update!(status: params.expect(:status)) if ServiceReminder.statuses.key?(params[:status])
    redirect_back fallback_location: service_reminders_path, status: :see_other
  end

  def contacted
    @reminder.contacted!(params[:comment])
    redirect_back fallback_location: service_reminders_path, notice: t("reminders.contacted_saved"), status: :see_other
  end

  def snooze
    @reminder.snooze!(params[:days].presence || 14)
    redirect_back fallback_location: service_reminders_path, notice: t("reminders.snoozed", date: l(@reminder.snoozed_until)), status: :see_other
  end

  def destroy
    @reminder.destroy
    redirect_back fallback_location: service_reminders_path, status: :see_other
  end

  private
    def set_reminder
      @reminder = ServiceReminder.find(params[:id])
    end
end
