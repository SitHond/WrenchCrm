class WorkOrdersController < ApplicationController
  before_action :set_work_order, only: %i[ show edit update destroy print status ]
  require_permission :manage_orders, only: %i[ new create edit update status ]
  require_permission :delete_records, only: :destroy

  def index
    scope = WorkOrder.search(params[:q]).includes(:client, :vehicle, :mechanic, :labor_lines, :part_lines)
    scope = scope.joins(:client).where(clients: { ad_source_id: params[:ad_source_id] }) if params[:ad_source_id].present?
    scope = case params[:status]
    when "all" then scope
    when *WorkOrder.statuses.keys then scope.where(status: params[:status])
    else scope.unfinished
    end
    respond_to do |format|
      format.html { @pagy, @work_orders = pagy(scope.recent_first, limit: 25) }
      format.csv do
        attr = ->(name) { WorkOrder.human_attribute_name(name) }
        send_csv("work-orders", [ "№", attr[:created_at], attr[:status], Client.model_name.human, Client.human_attribute_name(:phone),
                                  Vehicle.model_name.human, Vehicle.human_attribute_name(:plate_number), attr[:mechanic],
                                  t("work_orders.totals.labor"), t("work_orders.totals.parts"), attr[:total], t("work_orders.totals.paid") ],
                 scope.recent_first.includes(:payments).map { |o|
                   [ o.number, o.created_at, helpers.enum_label(WorkOrder, :status, o.status), o.client.display_name, o.client.phone,
                     o.vehicle.title, o.vehicle.plate_number, o.mechanic&.name, o.labor_total, o.parts_total, o.total, o.paid_total ]
                 })
      end
    end
  end

  def board
    @columns = WorkOrder::OPEN_STATUSES.index_with do |status|
      WorkOrder.where(status: status).includes(:client, :vehicle, :mechanic).order(:promised_at, :created_at)
    end
  end

  def show
    @labor_lines = @work_order.labor_lines.includes(performers: :employee).order(:created_at)
    @part_lines = @work_order.part_lines.order(:created_at)
    @payments = @work_order.payments
    @notes = @work_order.notes.visible_to(current_user).recent_first.includes(:author)
  end

  DOCUMENTS = %w[estimate work_order acceptance act invoice].freeze

  def print
    @shop = ShopSetting.current
    document = params[:doc].presence_in(DOCUMENTS) || (@work_order.estimate? ? "estimate" : "work_order")
    audit(:print, @work_order, document: document)
    render "work_orders/documents/#{document}", layout: "print"
  end

  def new
    vehicle = Vehicle.find_by(id: params[:vehicle_id])
    @work_order = WorkOrder.new(vehicle: vehicle, client: vehicle&.client, mileage: vehicle&.mileage,
                                status: params[:estimate] ? :estimate : :accepted, warranty_of_id: params[:warranty_of_id])
  end

  def create
    @work_order = WorkOrder.new(work_order_params)
    @work_order.status = :estimate if params.dig(:work_order, :status) == "estimate"
    if @work_order.save
      redirect_to @work_order, notice: t("flash.created", model: WorkOrder.model_name.human)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @work_order.update(work_order_params.except(:vehicle_id))
      redirect_to @work_order, notice: t("flash.updated", model: WorkOrder.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def status
    @work_order.change_status!(params.expect(:status))
    redirect_to @work_order, notice: t("work_orders.status_changed", status: helpers.enum_label(WorkOrder, :status, @work_order.status))
  rescue WorkOrder::PendingApproval
    redirect_to @work_order, alert: t("work_orders.pending_approval_block")
  rescue WorkOrder::StockShortage => e
    redirect_to @work_order, alert: t("work_orders.stock_shortage", parts: e.lines.map(&:name).join(", "))
  rescue ArgumentError
    redirect_to @work_order, alert: t("work_orders.invalid_transition")
  end

  def destroy
    if @work_order.destroy
      redirect_to work_orders_path, notice: t("flash.destroyed", model: WorkOrder.model_name.human), status: :see_other
    else
      redirect_to @work_order, alert: @work_order.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private
    def set_work_order
      @work_order = WorkOrder.find(params[:id])
    end

    def work_order_params
      permitted = params.expect(work_order: [ :vehicle_id, :mechanic_id, :advisor_id, :mileage, :complaint, :diagnosis,
                                              :recommendations, :fuel_level, :intake_condition, :intake_items, :replaced_parts, :warranty_of_id, :labor_discount_percent, :parts_discount_percent,
                                              :discount_amount, :complexity_level_id, :promised_at ])
      permitted[:client_id] = Vehicle.find_by(id: permitted[:vehicle_id])&.client_id if permitted.key?(:vehicle_id)
      permitted
    end
end
