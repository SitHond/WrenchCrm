class PurchaseReceiptLinesController < ApplicationController
  require_permission :manage_catalog
  before_action :set_receipt

  def create
    line = @receipt.lines.new(line_params)
    if line.save
      redirect_to purchase_receipt_path(@receipt, anchor: "lines")
    else
      redirect_to @receipt, alert: line.errors.full_messages.to_sentence
    end
  end

  def update
    line = @receipt.lines.find(params[:id])
    if line.update(line_params)
      redirect_to purchase_receipt_path(@receipt, anchor: "lines")
    else
      redirect_to @receipt, alert: line.errors.full_messages.to_sentence
    end
  end

  def destroy
    if @receipt.draft?
      @receipt.lines.find(params[:id]).destroy
      redirect_to purchase_receipt_path(@receipt, anchor: "lines"), status: :see_other
    else
      redirect_to @receipt, alert: t("purchase_receipts.posted_locked"), status: :see_other
    end
  end

  private
    def set_receipt
      @receipt = PurchaseReceipt.find(params[:purchase_receipt_id])
    end

    def line_params
      params.expect(purchase_receipt_line: [ :part_id, :quantity, :cost ])
    end
end
