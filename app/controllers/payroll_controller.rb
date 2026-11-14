class PayrollController < ApplicationController
  require_permission :manage_finance
  before_action :set_month

  def index
    @payrolls = Payroll.for_month(@month)
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
