class CashAccountsController < ApplicationController
  require_permission :manage_finance
  before_action :set_account, only: %i[ edit update ]

  def index
    @accounts = CashAccount.ordered
    @categories = ExpenseCategory.ordered
  end

  def new
    @account = CashAccount.new(position: CashAccount.maximum(:position).to_i + 1)
  end

  def create
    @account = CashAccount.new(account_params)
    if @account.save
      redirect_to cash_accounts_path, notice: t("flash.created", model: CashAccount.model_name.human)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @account.update(account_params)
      redirect_to cash_accounts_path, notice: t("flash.updated", model: CashAccount.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_account
      @account = CashAccount.find(params[:id])
    end

    def account_params
      params.expect(cash_account: [ :name, :kind, :position, :active ])
    end
end
