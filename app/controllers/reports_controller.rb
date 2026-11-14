class ReportsController < ApplicationController
  include PeriodFilter

  require_permission :view_reports

  def index
    @revenue = Report::Revenue.new(period_range)
    respond_to do |format|
      format.html
      format.csv do
        send_csv("money", [ t("reports.daily_income"), t("finance.income") ], @revenue.daily_income.map { |day, amount| [ day.to_date, amount ] })
      end
    end
  end

  def labor
    @report = Report::Labor.new(period_range)
    respond_to do |format|
      format.html
      format.csv do
        headers = [ t("reports.by_employee"), t("reports.orders"), t("reports.hours"), WorkOrderLabor.human_attribute_name(:total) ]
        rows = @report.by_employee.map { |name, orders, hours, sum| [ name || t("reports.no_employee"), orders, hours, sum ] } +
               [ [] ] + [ [ t("reports.by_service"), t("reports.times"), t("reports.hours"), WorkOrderLabor.human_attribute_name(:total) ] ] +
               @report.by_service
        send_csv("labor", headers, rows)
      end
    end
  end

  def parts
    @report = Report::Parts.new(period_range)
    respond_to do |format|
      format.html
      format.csv do
        send_csv("parts-margin", [ Part.model_name.human, Part.human_attribute_name(:quantity), t("reports.parts_revenue"), t("reports.parts_cost"), t("reports.margin"), "%" ],
                 @report.rows.map { |r| [ r.name, r.quantity, r.revenue, r.cost, r.margin, r.margin_percent ] })
      end
    end
  end

  def sources
    @report = Report::Sources.new(period_range)
    respond_to do |format|
      format.html
      format.csv do
        send_csv("sources", [ AdSource.model_name.human, t("reports.new_clients"), t("reports.closed_orders_short"), t("reports.paid") ],
                 @report.rows.map { |r| [ r.name || t("reports.no_source"), r.new_clients, r.orders, r.revenue ] })
      end
    end
  end

  def reorder
    @rows = Report::Reorder.new.rows
    respond_to do |format|
      format.html
      format.csv do
        send_csv("reorder", [ Part.model_name.human, Part.human_attribute_name(:quantity), Part.human_attribute_name(:min_quantity), t("reports.last_supplier"), t("reports.to_order"), PurchaseReceiptLine.human_attribute_name(:cost) ],
                 @rows.map { |r| [ r.part.label, r.part.quantity, r.part.min_quantity, r.last_supplier&.name, r.suggested, r.last_cost ] })
      end
    end
  end

  def stock
    @parts = Part.active.ordered.where("quantity <> 0")
    @total_cost = @parts.sum(&:stock_value)
    @total_retail = @parts.sum { |part| [ part.quantity, 0 ].max * part.price }
    respond_to do |format|
      format.html
      format.csv do
        send_csv("stock", [ Part.model_name.human, Part.human_attribute_name(:location), Part.human_attribute_name(:quantity), t("parts.average_cost"), t("parts.stock_value") ],
                 @parts.map { |p| [ p.label, p.location, p.quantity, p.cost, p.stock_value ] })
      end
    end
  end
end
