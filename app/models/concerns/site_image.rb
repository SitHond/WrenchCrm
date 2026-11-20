module SiteImage
  extend ActiveSupport::Concern

  included do
    has_one_attached :image
    validate :image_is_picture
  end

  private
    def image_is_picture
      return unless image.attached?

      errors.add(:image, :invalid) unless image.blob.content_type.in?(%w[image/png image/jpeg image/webp])
      errors.add(:image, :too_large) if image.blob.byte_size > 5.megabytes
    end
end
