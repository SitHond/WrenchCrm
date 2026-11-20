class SiteReview < ApplicationRecord
  validates :author, :text, presence: true
  validates :rating, inclusion: { in: 1..5 }

  scope :published, -> { where(published: true).order(:position, reviewed_on: :desc) }
end
