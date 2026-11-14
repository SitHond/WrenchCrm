class PayrollAdjustmentsController < ApplicationController
  require_permission :manage_finance

  def create
    adjustment = PayrollAdjustment.new(params.expect(payroll_adjustment: [ :employee_id, :amount, :period, :comment ]))
    if adjustment.save
      redirect_to payroll_path(adjustment.employee, month: adjustment.period.strftime("%Y-%m"))
    else
      redirect_back fallback_location: payroll_index_path, alert: adjustment.errors.full_messages.to_sentence
    end
  end

  def destroy
    adjustment = PayrollAdjustment.find(params[:id])
    adjustment.destroy
    redirect_to payroll_path(adjustment.employee, month: adjustment.period.strftime("%Y-%m")), status: :see_other
  end
end
