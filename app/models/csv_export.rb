require "csv"

# CSV that Excel opens correctly in Russian locales: UTF-8 with BOM and semicolons.
module CsvExport
  module_function

  def generate(headers, rows)
    "﻿" + CSV.generate(col_sep: ";") do |csv|
      csv << headers
      rows.each { |row| csv << row.map { |value| format(value) } }
    end
  end

  def format(value)
    case value
    when BigDecimal, Float then value.round(2).to_s("F").sub(/\.0\z/, "").tr(".", ",")
    when Time, ActiveSupport::TimeWithZone then I18n.l(value, format: :short)
    when Date then I18n.l(value)
    else value
    end
  end

  def filename(name)
    "#{name}-#{Date.current.iso8601}.csv"
  end
end
