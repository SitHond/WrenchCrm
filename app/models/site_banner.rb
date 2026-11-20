class SiteBanner < ApplicationRecord
  include SiteSchedule
  include SiteImage

  validates :title, presence: true
  validates :button_url, format: { with: %r{\A(https?://|/|#)}i }, allow_blank: true

  scope :ordered, -> { order(:position, :id) }
end
