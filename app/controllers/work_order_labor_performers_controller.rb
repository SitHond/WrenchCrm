class WorkOrderLaborPerformersController < ApplicationController
  require_permission :manage_orders
  before_action :set_labor

  def create
    performer = @labor.performers.new(params.expect(work_order_labor_performer: [ :employee_id, :share ]))
    if !@work_order.editable?
      redirect_to @work_order, alert: t("activerecord.errors.messages.order_locked")
    elsif performer.save
      redirect_to work_order_path(@work_order, anchor: "work_order_labor")
    else
      redirect_to work_order_path(@work_order, anchor: "work_order_labor"), alert: performer.errors.full_messages.to_sentence
    end
  end

  def destroy
    @labor.performers.find(params[:id]).destroy if @work_order.editable?
    redirect_to work_order_path(@work_order, anchor: "work_order_labor"), status: :see_other
  end

  private
    def set_labor
      @work_order = WorkOrder.find(params[:work_order_id])
      @labor = @work_order.labor_lines.find(params[:work_order_labor_id])
    end
end
