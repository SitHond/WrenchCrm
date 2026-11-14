class Bay < ApplicationRecord
  has_many :appointments, dependent: :nullify

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :name) }
end
