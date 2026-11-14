module Searchable
  extend ActiveSupport::Concern

  class_methods do
    def like_pattern(query)
      "%#{sanitize_sql_like(query.to_s.strip)}%"
    end

    def digits_pattern(query)
      digits = query.to_s.gsub(/\D/, "")
      digits.length >= 3 ? "%#{digits}%" : nil
    end
  end
end
