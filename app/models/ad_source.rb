# Where a client heard about the shop.
class AdSource < ApplicationRecord
  has_many :clients, dependent: :nullify

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }
end
