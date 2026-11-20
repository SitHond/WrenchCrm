class SiteSetting < ApplicationRecord
  THEMES = %w[orange blue green graphite].freeze

  has_one_attached :logo

  validates :theme, inclusion: { in: THEMES }
  validates :metrika_id, format: { with: /\A\d+\z/ }, allow_blank: true
  validate :logo_is_image

  def self.current
    first || create!(title: ShopSetting.current.display_name)
  end

  def display_title = title.presence || ShopSetting.current.display_name

  private
    def logo_is_image
      return unless logo.attached?

      errors.add(:logo, :invalid) unless logo.blob.content_type.in?(%w[image/png image/jpeg image/webp image/svg+xml])
      errors.add(:logo, :too_large) if logo.blob.byte_size > 2.megabytes
    end
end
