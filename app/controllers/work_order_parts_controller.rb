class WorkOrderPartsController < ApplicationController
  include OrderLinesController

  private
    def lines
      @work_order.part_lines
    end

    def line_params
      params.expect(work_order_part: [ :part_id, :name, :quantity, :price ])
    end
end
