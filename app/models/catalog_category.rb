class CatalogCategory < ApplicationRecord
  enum :kind, { part: 0, service: 1 }

  has_many :parts, foreign_key: :category_id, dependent: :nullify, inverse_of: :category
  has_many :services, foreign_key: :category_id, dependent: :nullify, inverse_of: :category

  validates :name, presence: true, uniqueness: { scope: :kind, case_sensitive: false }

  scope :ordered, -> { order(:name) }
end
