class PaymentsController < ApplicationController
  require_permission :manage_payments
  before_action :set_work_order

  def create
    payment = @work_order.payments.new(params.expect(payment: [ :amount, :payment_method, :cash_account_id, :comment ]))
    if payment.save
      redirect_to work_order_path(@work_order, anchor: "payments"), notice: t("payments.created")
    else
      redirect_to @work_order, alert: payment.errors.full_messages.to_sentence
    end
  end

  def destroy
    @work_order.payments.find(params[:id]).destroy
    redirect_to work_order_path(@work_order, anchor: "payments"), notice: t("flash.destroyed", model: Payment.model_name.human), status: :see_other
  end

  private
    def set_work_order
      @work_order = WorkOrder.find(params[:work_order_id])
    end
end
