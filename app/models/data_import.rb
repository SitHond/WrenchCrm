# An uploaded file waiting to be mapped and imported, and the outcome afterwards.
class DataImport < ApplicationRecord
  DEFINITIONS = {
    "clients" => Imports::Clients, "parts" => Imports::Parts, "services" => Imports::Services, "suppliers" => Imports::Suppliers
  }.freeze
  MODES = %w[skip update].freeze
  MAX_SIZE = 10.megabytes
  MAX_ERRORS = 500

  belongs_to :created_by, class_name: "User", optional: true

  validates :kind, inclusion: { in: DEFINITIONS.keys + [ "splus" ] }
  validates :mode, inclusion: { in: MODES }
  validate :content_readable, on: :create, unless: :splus?

  before_create { self.created_by ||= Current.user }

  scope :recent_first, -> { order(created_at: :desc) }

  def splus? = kind == "splus"

  def definition = DEFINITIONS.fetch(kind)

  def table
    @table ||= Imports::TableReader.read(content, filename)
  end

  def effective_mapping
    mapping.presence || definition.auto_mapping(table.headers).transform_values(&:to_s)
  end

  def values_for(row)
    effective_mapping.each_with_object({}) do |(key, index), values|
      values[key] = row[index.to_i].to_s.strip if index.present?
    end
  end

  def missing_required
    definition.fields.select { |field| field.required && effective_mapping[field.key.to_s].blank? }
  end

  # Imports every row; each row in its own transaction so one bad row does not stop the rest.
  def run!
    counts = Hash.new(0)
    errors = []
    importer = definition.new(mode: mode)
    Current.set(importing: true) do
      table.rows.each_with_index do |row, index|
        result = begin
          ApplicationRecord.transaction(requires_new: true) { importer.import_row(values_for(row)) }
        rescue ActiveRecord::ActiveRecordError, ArgumentError => e
          Imports::Definition::Result.new(:failed, nil, [ e.message ])
        end
        counts[result.status] += 1
        errors << { "row" => index + 2, "values" => row, "messages" => result.errors } if result.status == :failed && errors.size < MAX_ERRORS
      end
    end
    update!(status: "done", result: { "counts" => counts, "errors" => errors, "headers" => table.headers }, content: nil)
  end

  def counts = result.fetch("counts", {})

  def errors_csv
    headers = [ I18n.t("imports.error_row"), I18n.t("imports.error_messages"), *table_headers ]
    CsvExport.generate(headers, result.fetch("errors", []).map { |e| [ e["row"], e["messages"].join("; "), *e["values"] ] })
  end

  def table_headers = result["headers"] || []

  private
    def content_readable
      return errors.add(:content, :blank) if content.blank?
      return errors.add(:content, :too_large) if content.bytesize > MAX_SIZE

      errors.add(:content, :no_rows) if table.headers.empty? || table.rows.empty?
    rescue CSV::MalformedCSVError, Zip::Error, ArgumentError => e
      errors.add(:content, :unreadable, message: e.message.truncate(120))
    end
end
