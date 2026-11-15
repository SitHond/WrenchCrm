class DataImportsController < ApplicationController
  require_permission :admin
  before_action :set_import, only: %i[ show update errors ]

  def index
    @imports = DataImport.recent_first.limit(20)
  end

  def create
    file = params[:file]
    @import = DataImport.new(kind: params[:kind], filename: file&.original_filename, content: file&.read)
    if @import.save
      redirect_to data_import_path(@import)
    else
      redirect_to data_imports_path, alert: @import.errors.full_messages.to_sentence
    end
  end

  def show
  end

  # Saves the column mapping and mode; with run=1 also performs the import.
  def update
    return redirect_to(data_import_path(@import)) if @import.status == "done"

    @import.update!(mapping: params.fetch(:mapping, {}).permit!.to_h.compact_blank, mode: params[:mode].presence_in(DataImport::MODES) || "skip")
    if params[:run].present?
      if @import.missing_required.any?
        redirect_to data_import_path(@import), alert: t("imports.required_missing", fields: @import.missing_required.map(&:label).join(", "))
      else
        @import.run!
        audit(:import, nil, kind: @import.kind, counts: @import.counts)
        redirect_to data_import_path(@import), notice: t("imports.done")
      end
    else
      redirect_to data_import_path(@import)
    end
  end

  def errors
    send_data @import.errors_csv, filename: "import-errors-#{@import.id}.csv", type: "text/csv; charset=utf-8"
  end

  def template
    definition = DataImport::DEFINITIONS.fetch(params[:kind]) { raise ActiveRecord::RecordNotFound }
    send_data definition.template_csv, filename: "wrenchcrm-#{params[:kind]}-template.csv", type: "text/csv; charset=utf-8"
  end

  def splus
    files = Array(params[:files]).compact_blank.to_h { |file| [ file.original_filename, file.read ] }
    tables = Imports::Splus.detect(files)
    result = Imports::Splus.new(tables).run!
    audit(:import, nil, kind: "splus", counts: result["counts"])
    import = DataImport.create!(kind: "splus", filename: files.keys.join(", "), status: "done", result: result.merge("detected" => tables.keys.map(&:to_s)))
    redirect_to data_import_path(import), notice: t("imports.done")
  rescue ArgumentError, ActiveRecord::ActiveRecordError, CSV::MalformedCSVError => e
    redirect_to data_imports_path, alert: t("imports.splus.failed", message: e.message.truncate(200))
  end

  private
    def set_import
      @import = DataImport.find(params[:id])
    end
end
