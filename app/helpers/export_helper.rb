module ExportHelper
  # "Export to Excel" link that keeps the current filters.
  def csv_export_link
    link_to t("export.csv"), url_for(request.query_parameters.merge(format: :csv)), class: "btn", data: { turbo: false }
  end
end
