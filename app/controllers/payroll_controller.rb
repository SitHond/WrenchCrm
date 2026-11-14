class PayrollController < ApplicationController
  require_permission :manage_finance
  before_action :set_month

  def index
    @payrolls = Payroll.for_month(@month)
    respond_to do |format|
      format.html
      format.csv do
        send_csv("payroll-#{@month.strftime('%Y-%m')}",
                 [ Employee.model_name.human, Employee.human_attribute_name(:monthly_salary), t("payroll.labor_pay"), t("payroll.orders_pay"),
                   t("payroll.adjustments"), t("payroll.accrued"), t("payroll.paid"), t("payroll.due") ],
                 @payrolls.map { |p| [ p.employee.name, p.employee.monthly_salary, p.labor_pay, p.orders_pay, p.adjustments_total, p.accrued, p.paid, p.due ] })
      end
    end
  end

  def show
    @payroll = Payroll.new(Employee.find(params[:id]), @month)
  end

  private
    def set_month
      @month = Date.iso8601("#{params[:month]}-01")
    rescue Date::Error
      @month = Date.current.beginning_of_month
    end
end
