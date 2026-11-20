class SitePage < ApplicationRecord
  normalizes :slug, with: ->(slug) { slug.to_s.strip.downcase.tr(" _", "--").gsub(/[^a-z0-9\-]/, "").squeeze("-").delete_prefix("-").delete_suffix("-") }

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/ }

  before_validation { self.slug = title.to_s.downcase.then { |t| I18n.transliterate(t) rescue t } if slug.blank? }

  scope :published, -> { where(published: true) }
  scope :menu, -> { published.where(show_in_menu: true).order(:position, :id) }
end
