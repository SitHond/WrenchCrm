# Content shown between optional start and end dates.
module SiteSchedule
  extend ActiveSupport::Concern

  included do
    scope :current, -> {
      where(active: true)
        .where("starts_on IS NULL OR starts_on <= ?", Date.current)
        .where("ends_on IS NULL OR ends_on >= ?", Date.current)
    }
  end
end
