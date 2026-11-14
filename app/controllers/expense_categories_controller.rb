class ExpenseCategoriesController < ApplicationController
  require_permission :manage_finance

  def create
    category = ExpenseCategory.new(params.expect(expense_category: [ :name, :kind ]))
    if category.save
      redirect_to cash_accounts_path, notice: t("flash.created", model: ExpenseCategory.model_name.human)
    else
      redirect_to cash_accounts_path, alert: category.errors.full_messages.to_sentence
    end
  end

  def update
    category = ExpenseCategory.find(params[:id])
    category.update(active: !category.active)
    redirect_to cash_accounts_path
  end
end
