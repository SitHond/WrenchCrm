class WorkOrderLaborsController < ApplicationController
  include OrderLinesController

  private
    def lines
      @work_order.labor_lines
    end

    def line_params
      params.expect(work_order_labor: [ :service_id, :employee_id, :name, :quantity, :price, :save_to_catalog ])
    end
end
