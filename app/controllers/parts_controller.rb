class PartsController < ApplicationController
  before_action :set_part, only: %i[ edit update destroy receive ]
  require_permission :manage_catalog, except: :index

  def index
    scope = Part.search(params[:q])
    scope = case params[:status]
    when "low" then scope.low_stock
    when "all" then scope
    else scope.active
    end
    @pagy, @parts = pagy(scope.ordered, limit: 50)
  end

  def new
    @part = Part.new
  end

  def create
    @part = Part.new(part_params)
    if @part.save
      redirect_to parts_path, notice: t("flash.created", model: Part.model_name.human)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @part.update(part_params.except(:quantity))
      redirect_to parts_path, notice: t("flash.updated", model: Part.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def receive
    amount = params[:amount].to_d
    if amount.positive?
      @part.adjust_stock!(amount)
      redirect_to parts_path, notice: t("parts.received", name: @part.name, quantity: helpers.quantity_with_unit(amount, @part.unit))
    else
      redirect_to parts_path, alert: t("parts.receive_invalid")
    end
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
      params.expect(part: [ :name, :sku, :brand, :unit, :cost, :price, :quantity, :min_quantity, :active ])
    end
end
