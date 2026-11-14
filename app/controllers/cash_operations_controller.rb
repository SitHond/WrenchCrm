class CashOperationsController < ApplicationController
  include PeriodFilter

  require_permission :manage_finance

  def index
    @accounts = CashAccount.active.ordered
    scope = CashOperation.in_period(period_range).preload(:cash_account, :expense_category, :supplier, :employee, :source)
    scope = scope.where(cash_account_id: params[:account_id]) if params[:account_id].present?
    scope = scope.where(kind: params[:kind]) if CashOperation.kinds.key?(params[:kind])
    @income = scope.incoming.where.not(kind: :transfer).sum(:amount)
    @expense = -scope.outgoing.where.not(kind: :transfer).sum(:amount)
    @by_category = scope.expense.group(:expense_category_id).sum(:amount)
    @pagy, @operations = pagy(scope.recent_first, limit: 50)
  end

  def new
    kind = params[:kind].presence_in(CashOperation::MANUAL_KINDS) || "expense"
    @operation = CashOperation.new(kind: kind, occurred_at: Time.current, supplier_id: params[:supplier_id],
                                   cash_account: CashAccount.active.ordered.first)
  end

  def create
    @operation = CashOperation.new(operation_params)
    unless @operation.kind.in?(CashOperation::MANUAL_KINDS)
      return redirect_to cash_operations_path, alert: t("flash.forbidden")
    end

    @operation.amount = @operation.other_income? ? @operation.amount.to_d.abs : -@operation.amount.to_d.abs
    if @operation.save
      redirect_to cash_operations_path, notice: t("flash.created", model: CashOperation.model_name.human)
    else
      @operation.amount = @operation.amount&.abs
      render :new, status: :unprocessable_entity
    end
  end

  def transfer
    from = CashAccount.find(params[:from_id])
    to = CashAccount.find(params[:to_id])
    amount = params[:amount].to_d
    if from == to || !amount.positive?
      redirect_to cash_operations_path, alert: t("finance.transfer_invalid")
    else
      CashOperation.transfer!(from: from, to: to, amount: amount, comment: params[:comment].presence)
      redirect_to cash_operations_path, notice: t("finance.transferred")
    end
  end

  def destroy
    operation = CashOperation.find(params[:id])
    if operation.manual?
      operation.destroy
      redirect_to cash_operations_path, notice: t("flash.destroyed", model: CashOperation.model_name.human), status: :see_other
    else
      redirect_to cash_operations_path, alert: t("finance.delete_from_source"), status: :see_other
    end
  end

  private
    def operation_params
      params.expect(cash_operation: [ :kind, :cash_account_id, :amount, :occurred_at, :expense_category_id, :supplier_id, :comment ])
    end
end
