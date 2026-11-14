class SalaryPayoutsController < ApplicationController
  require_permission :manage_finance

  def create
    payout = SalaryPayout.new(params.expect(salary_payout: [ :employee_id, :amount, :period, :paid_on, :cash_account_id, :comment ]))
    if payout.save
      redirect_to payroll_path(payout.employee, month: payout.period.strftime("%Y-%m")), notice: t("payroll.paid_out")
    else
      redirect_back fallback_location: payroll_index_path, alert: payout.errors.full_messages.to_sentence
    end
  end

  def destroy
    payout = SalaryPayout.find(params[:id])
    payout.destroy
    redirect_to payroll_path(payout.employee, month: payout.period.strftime("%Y-%m")), status: :see_other
  end
end
