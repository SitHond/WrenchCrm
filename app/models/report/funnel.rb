module Report
  # Leads created in the period by source and how far they got.
  class Funnel
    Row = Struct.new(:name, :total, :booked, :won, :lost) do
      def conversion = total.zero? ? 0 : (won * 100.0 / total).round(1)
    end

    def initialize(range)
      @range = range
    end

    def rows
      names = AdSource.pluck(:id, :name).to_h
      counts = Lead.where(created_at: @range).group(:ad_source_id, :status).count
      counts.group_by { |(source, _), _| source }.map do |source, pairs|
        by_status = pairs.to_h { |(_, status), count| [ status, count ] }
        Row.new(names[source], by_status.values.sum, by_status["booked"].to_i + by_status["won"].to_i, by_status["won"].to_i, by_status["lost"].to_i)
      end.sort_by { |row| -row.total }
    end

    def lost_reasons
      Lead.lost.where(created_at: @range).group(:lost_reason).count.sort_by { |_, count| -count }
    end
  end
end
