class VehiclesController < ApplicationController
  before_action :set_vehicle, only: %i[ show edit update destroy ]
  require_permission :manage_clients, only: %i[ new create edit update ]
  require_permission :delete_records, only: :destroy

  def index
    @pagy, @vehicles = pagy(Vehicle.search(params[:q]).includes(:client).ordered, limit: 25)
  end

  def show
    audit(:view, @vehicle)
    @work_orders = @vehicle.work_orders.includes(:mechanic, :labor_lines, :part_lines)
    @appointments = @vehicle.appointments.upcoming.includes(:bay)
    @reminders = @vehicle.service_reminders.active.order(:due_on)
    @notes = @vehicle.notes.visible_to(current_user).recent_first.includes(:author)
  end

  def new
    @vehicle = Client.find(params.expect(:client_id)).vehicles.new
  end

  def create
    @vehicle = Vehicle.new(vehicle_params)
    if @vehicle.save
      redirect_to @vehicle, notice: t("flash.created", model: Vehicle.model_name.human)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @vehicle.update(vehicle_params.except(:client_id))
      audit(:update, @vehicle, fields: audit_changes(@vehicle))
      redirect_to @vehicle, notice: t("flash.updated", model: Vehicle.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    client = @vehicle.client
    if @vehicle.destroy
      redirect_to client, notice: t("flash.destroyed", model: Vehicle.model_name.human), status: :see_other
    else
      redirect_to @vehicle, alert: @vehicle.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private
    def set_vehicle
      @vehicle = Vehicle.find(params[:id])
    end

    def vehicle_params
      params.expect(vehicle: [ :client_id, :make, :model, :year, :vin, :plate_number, :color, :engine, :mileage ])
    end
end
