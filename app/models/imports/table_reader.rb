require "csv"

module Imports
  # Reads an uploaded CSV or XLSX into headers and rows of strings.
  # CSV: UTF-8 (with or without BOM) or Windows-1251, separator ; , or tab.
  class TableReader
    Table = Struct.new(:headers, :rows)
    MAX_ROWS = 20_000

    def self.read(content, filename)
      new(content, filename).read
    end

    def initialize(content, filename)
      @content = content.to_s.b
      @filename = filename.to_s
    end

    def read
      xlsx? ? read_xlsx : read_csv
    end

    def self.normalize_header(value)
      value.to_s.downcase.tr("ё", "е").gsub(/[^\p{L}\p{N}]+/, " ").strip
    end

    private
      def xlsx?
        @filename.downcase.end_with?(".xlsx") || @content.start_with?("PK\x03\x04".b)
      end

      def read_xlsx
        Tempfile.create([ "import", ".xlsx" ], binmode: true) do |file|
          file.write(@content)
          file.flush
          sheet = Roo::Excelx.new(file.path).sheet(0)
          rows = sheet.each_row_streaming(pad_cells: true).first(MAX_ROWS + 1).map { |row| row.map { |cell| cell_value(cell) } }
          table(rows)
        end
      end

      def cell_value(cell)
        value = cell&.value
        case value
        when Float then value % 1 == 0 ? value.to_i.to_s : value.to_s
        when Date, Time, DateTime then value.strftime("%d.%m.%Y")
        else value.to_s
        end
      end

      def read_csv
        text = decode(@content)
        rows = CSV.parse(text, col_sep: separator(text), liberal_parsing: true).first(MAX_ROWS + 1)
        table(rows.map { |row| row.map(&:to_s) })
      end

      def decode(bytes)
        bytes = bytes.byteslice(3..) if bytes.start_with?("\xEF\xBB\xBF".b)
        utf8 = bytes.dup.force_encoding("UTF-8")
        utf8.valid_encoding? ? utf8 : bytes.force_encoding("Windows-1251").encode("UTF-8")
      end

      def separator(text)
        first = text.lines.first.to_s
        [ ";", ",", "\t" ].max_by { |sep| first.count(sep) }
      end

      def table(rows)
        rows = rows.reject { |row| row.all?(&:blank?) }
        headers = (rows.shift || []).map(&:strip)
        # Drop the empty trailing column many exports add.
        keep = headers.each_index.reject { |i| headers[i].blank? && rows.all? { |row| row[i].blank? } }
        Table.new(keep.map { |i| headers[i] }, rows.map { |row| keep.map { |i| row[i].to_s.strip } })
      end
  end
end
