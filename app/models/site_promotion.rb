class SitePromotion < ApplicationRecord
  include SiteSchedule
  include SiteImage

  validates :title, presence: true

  scope :ordered, -> { order(Arel.sql("ends_on IS NULL"), :ends_on, :id) }
end
