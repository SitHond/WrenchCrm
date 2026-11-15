module Imports
  # Describes one importable entity: its fields, how file columns map onto them and how a row is saved.
  class Definition
    Field = Struct.new(:key, :aliases, :required, :type, keyword_init: true) do
      def label = I18n.t("imports.fields.#{key}")
    end

    class << self
      def fields = @fields ||= []

      def field(key, aliases: [], required: false, type: :string)
        fields << Field.new(key: key, aliases: aliases, required: required, type: type)
      end

      def kind = name.demodulize.underscore

      def label = I18n.t("imports.kinds.#{kind}")

      # Column index per field, guessed from header names and aliases.
      def auto_mapping(headers)
        normalized = headers.map { |h| TableReader.normalize_header(h) }
        fields.each_with_object({}) do |field, mapping|
          candidates = [ field.label, field.key.to_s.tr("_", " "), *field.aliases ].map { |a| TableReader.normalize_header(a) }
          index = normalized.index { |h| candidates.include?(h) }
          mapping[field.key.to_s] = index if index && !mapping.value?(index)
        end
      end

      def template_csv
        CsvExport.generate(fields.map(&:label), [ fields.map { |f| example_values[f.key] } ])
      end

      def example_values = {}
    end

    Result = Struct.new(:status, :record, :errors) # status: :created, :updated, :skipped, :failed

    def initialize(mode:)
      @mode = mode.to_s
    end

    def update? = @mode == "update"

    # values: { field_key => string }
    def import_row(values)
      raise NotImplementedError
    end

    private
      def decimal(value)
        return if value.blank?

        value.to_s.gsub(/[\s ]/, "").tr(",", ".").gsub(/[^\d.\-]/, "").presence&.to_d
      end

      def integer(value)
        decimal(value)&.round&.to_i
      end

      def date(value)
        return if value.blank?

        Date.parse(value.to_s.tr("/", "."))
      rescue Date::Error
        nil
      end

      def phone_digits(value)
        digits = value.to_s.gsub(/\D/, "")
        digits.length >= 10 ? digits.last(10) : nil
      end

      def find_client_by_phone(phone)
        digits = phone_digits(phone)
        return unless digits

        Client.where("RIGHT(regexp_replace(phone, '\\D', '', 'g'), 10) = ?", digits)
          .or(Client.where("RIGHT(regexp_replace(COALESCE(phone2, ''), '\\D', '', 'g'), 10) = ?", digits)).first
      end

      # Assign only present values; on update existing non-blank values are overwritten.
      def assign(record, attributes)
        attributes.each do |key, value|
          next if value.nil? || (value.respond_to?(:empty?) && value.empty?)

          record.public_send(:"#{key}=", value)
        end
      end

      def save(record, existed)
        if existed && !update?
          Result.new(:skipped, record, [])
        elsif record.save
          Result.new(existed ? :updated : :created, record, [])
        else
          Result.new(:failed, record, record.errors.full_messages)
        end
      end
  end
end
