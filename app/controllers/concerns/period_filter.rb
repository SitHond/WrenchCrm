# Reads ?from=YYYY-MM-DD&to=YYYY-MM-DD, defaulting to the current month.
module PeriodFilter
  extend ActiveSupport::Concern

  included do
    helper_method :period_from, :period_to
  end

  private
    def period_from
      @period_from ||= parse_period_date(params[:from]) || Date.current.beginning_of_month
    end

    def period_to
      @period_to ||= [ parse_period_date(params[:to]) || Date.current.end_of_month, period_from ].max
    end

    def period_range
      period_from.in_time_zone.beginning_of_day..period_to.in_time_zone.end_of_day
    end

    def parse_period_date(value)
      Date.iso8601(value.to_s)
    rescue Date::Error
      nil
    end
end
