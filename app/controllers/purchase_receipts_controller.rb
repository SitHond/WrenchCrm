class PurchaseReceiptsController < ApplicationController
  before_action :set_receipt, only: %i[ show edit update destroy post ]
  require_permission :manage_catalog, except: %i[ index show ]

  def index
    scope = PurchaseReceipt.includes(:supplier, :lines).recent_first
    scope = scope.where(supplier_id: params[:supplier_id]) if params[:supplier_id].present?
    scope = scope.where(status: params[:status]) if PurchaseReceipt.statuses.key?(params[:status])
    @pagy, @receipts = pagy(scope, limit: 25)
  end

  def show
    @lines = @receipt.lines.includes(:part).order(:created_at)
  end

  def new
    @receipt = PurchaseReceipt.new(supplier_id: params[:supplier_id], received_on: Date.current)
  end

  def create
    @receipt = PurchaseReceipt.new(receipt_params)
    if @receipt.save
      redirect_to @receipt, notice: t("flash.created", model: PurchaseReceipt.model_name.human)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @receipt.update(receipt_params)
      redirect_to @receipt, notice: t("flash.updated", model: PurchaseReceipt.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def post
    @receipt.post!
    redirect_to @receipt, notice: t("purchase_receipts.posted")
  rescue ArgumentError
    redirect_to @receipt, alert: t("purchase_receipts.post_failed")
  end

  def destroy
    if @receipt.draft?
      @receipt.destroy
      redirect_to purchase_receipts_path, notice: t("flash.destroyed", model: PurchaseReceipt.model_name.human), status: :see_other
    else
      redirect_to @receipt, alert: t("purchase_receipts.posted_locked"), status: :see_other
    end
  end

  private
    def set_receipt
      @receipt = PurchaseReceipt.find(params[:id])
    end

    def receipt_params
      params.expect(purchase_receipt: [ :supplier_id, :number, :received_on, :comment ])
    end
end
