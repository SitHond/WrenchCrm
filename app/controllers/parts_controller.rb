class PartsController < ApplicationController
  before_action :set_part, only: %i[ show edit update destroy receive write_off count add_analog remove_analog ]
  require_permission :manage_catalog, except: %i[ index show ]

  def index
    scope = Part.search(params[:q]).includes(:category)
    scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?
    scope = case params[:status]
    when "low" then scope.low_stock
    when "all" then scope
    else scope.active
    end
    respond_to do |format|
      format.html { @pagy, @parts = pagy(scope.ordered, limit: 50) }
      format.csv do
        attr = ->(name) { Part.human_attribute_name(name) }
        send_csv("parts", [ attr[:sku], attr[:oem], attr[:name], attr[:brand], attr[:category_id], attr[:location], attr[:unit],
                            attr[:quantity], attr[:min_quantity], attr[:cost], attr[:price] ],
                 scope.ordered.map { |p|
                   [ p.sku, p.oem, p.name, p.brand, p.category&.name, p.location, t("parts.units.#{p.unit}"), p.quantity, p.min_quantity, p.cost, p.price ]
                 })
      end
    end
  end

  def show
    @movements = @part.stock_movements.recent_first.includes(:source, :created_by).limit(50)
    @analogs = @part.all_analogs.ordered
  end

  def new
    @part = Part.new
  end

  def create
    @part = Part.new(part_params)
    if @part.save
      redirect_to @part, notice: t("flash.created", model: Part.model_name.human)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @part.update(part_params.except(:quantity))
      redirect_to @part, notice: t("flash.updated", model: Part.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def receive
    amount = params[:amount].to_d
    if amount.positive?
      @part.adjust_stock!(amount, kind: :manual, comment: params[:comment].presence)
      redirect_back fallback_location: parts_path, notice: t("parts.received", name: @part.name, quantity: helpers.quantity_with_unit(amount, @part.unit))
    else
      redirect_back fallback_location: parts_path, alert: t("parts.receive_invalid")
    end
  end

  def write_off
    amount = params[:amount].to_d
    if amount.positive?
      @part.adjust_stock!(-amount, kind: :write_off, comment: params[:comment].presence)
      redirect_to @part, notice: t("parts.written_off", quantity: helpers.quantity_with_unit(amount, @part.unit))
    else
      redirect_to @part, alert: t("parts.receive_invalid")
    end
  end

  def count
    if params[:counted].present? && params[:counted].to_d >= 0
      @part.set_quantity!(params[:counted], comment: params[:comment].presence)
      redirect_to @part, notice: t("parts.counted", quantity: helpers.quantity_with_unit(@part.quantity, @part.unit))
    else
      redirect_to @part, alert: t("parts.receive_invalid")
    end
  end

  def add_analog
    analog = Part.find(params[:analog_id])
    PartAnalog.link!(@part, analog)
    redirect_to @part, notice: t("parts.analog_added", name: analog.name)
  end

  def remove_analog
    PartAnalog.unlink!(@part, Part.find(params[:analog_id]))
    redirect_to @part, status: :see_other
  end

  def destroy
    @part.destroy
    redirect_to parts_path, notice: t("flash.destroyed", model: Part.model_name.human), status: :see_other
  end

  private
    def set_part
      @part = Part.find(params[:id])
    end

    def part_params
      params.expect(part: [ :name, :sku, :oem, :brand, :location, :unit, :cost, :price, :quantity, :min_quantity, :active, :auto_price, :category_id, :warranty_months, :warranty_km ])
    end
end
