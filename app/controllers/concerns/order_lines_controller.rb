module OrderLinesController
  extend ActiveSupport::Concern

  included do
    require_permission :manage_orders
    before_action :set_work_order
  end

  def create
    line = lines.new(line_params)
    save_and_redirect(line) { line.save }
  end

  def update
    line = lines.find(params[:id])
    save_and_redirect(line) { line.update(line_params) }
  end

  def destroy
    line = lines.find(params[:id])
    if @work_order.editable?
      line.destroy
      redirect_to @work_order, status: :see_other
    else
      redirect_to @work_order, alert: t("activerecord.errors.messages.order_locked"), status: :see_other
    end
  end

  private
    def set_work_order
      @work_order = WorkOrder.find(params[:work_order_id])
    end

    def save_and_redirect(line)
      if yield
        redirect_to work_order_path(@work_order, anchor: line.class.model_name.element)
      else
        redirect_to @work_order, alert: line.errors.full_messages.to_sentence
      end
    end
end
