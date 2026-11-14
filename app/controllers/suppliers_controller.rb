class SuppliersController < ApplicationController
  before_action :set_supplier, only: %i[ show edit update destroy ]
  require_permission :manage_catalog, except: %i[ index show ]

  def index
    scope = Supplier.search(params[:q])
    scope = scope.active unless params[:status] == "all"
    @suppliers = scope.ordered
  end

  def show
    @receipts = @supplier.purchase_receipts.recent_first.includes(:lines).limit(30)
    @payments = @supplier.cash_operations.supplier_payment.recent_first.includes(:cash_account).limit(30)
  end

  def new
    @supplier = Supplier.new
  end

  def create
    @supplier = Supplier.new(supplier_params)
    if @supplier.save
      redirect_to @supplier, notice: t("flash.created", model: Supplier.model_name.human)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @supplier.update(supplier_params)
      redirect_to @supplier, notice: t("flash.updated", model: Supplier.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @supplier.destroy
      redirect_to suppliers_path, notice: t("flash.destroyed", model: Supplier.model_name.human), status: :see_other
    else
      redirect_to @supplier, alert: @supplier.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private
    def set_supplier
      @supplier = Supplier.find(params[:id])
    end

    def supplier_params
      params.expect(supplier: [ :name, :inn, :phone, :email, :contact_person, :comment, :active ])
    end
end
