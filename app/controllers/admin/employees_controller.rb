module Admin
  class EmployeesController < ApplicationController
    require_permission :admin
    before_action :set_employee, only: %i[ edit update destroy ]

    def index
      @employees = Employee.ordered.includes(:user)
    end

    def new
      @employee = Employee.new
    end

    def create
      @employee = Employee.new(employee_params)
      if @employee.save
        redirect_to admin_employees_path, notice: t("flash.created", model: Employee.model_name.human)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @employee.update(employee_params)
        redirect_to admin_employees_path, notice: t("flash.updated", model: Employee.model_name.human)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @employee.destroy
      redirect_to admin_employees_path, notice: t("flash.destroyed", model: Employee.model_name.human), status: :see_other
    end

    private
      def set_employee
        @employee = Employee.find(params[:id])
      end

      def employee_params
        params.expect(employee: [ :name, :position, :phone, :active, :user_id, :monthly_salary, :labor_percent, :order_percent ])
      end
  end
end
