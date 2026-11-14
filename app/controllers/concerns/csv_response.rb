module CsvResponse
  extend ActiveSupport::Concern

  private
    def send_csv(name, headers, rows)
      send_data CsvExport.generate(headers, rows), filename: CsvExport.filename(name), type: "text/csv; charset=utf-8"
    end
end
