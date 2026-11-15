require "zip"

class ExportsController < ApplicationController
  require_permission :admin

  # Whole database as a ZIP of CSV files. Clients, parts, services and suppliers use the import template columns.
  def full
    data = Zip::OutputStream.write_buffer do |zip|
      FullExport.files.each do |name, csv|
        zip.put_next_entry(name)
        zip.write(csv)
      end
    end
    send_data data.string, filename: "wrenchcrm-export-#{Date.current.iso8601}.zip", type: "application/zip"
  end
end
