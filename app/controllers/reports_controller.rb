class ReportsController < ApplicationController
  include PeriodFilter

  require_permission :view_reports

  def index
    @revenue = Report::Revenue.new(period_range)
  end

  def labor
    @report = Report::Labor.new(period_range)
  end

  def parts
    @report = Report::Parts.new(period_range)
  end

  def sources
    @report = Report::Sources.new(period_range)
  end

  def reorder
    @rows = Report::Reorder.new.rows
  end

  def stock
    @parts = Part.active.ordered.where("quantity <> 0")
    @total_cost = @parts.sum(&:stock_value)
    @total_retail = @parts.sum { |part| [ part.quantity, 0 ].max * part.price }
  end
end
