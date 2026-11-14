class Service < ApplicationRecord
  include Searchable

  has_many :work_order_labors, dependent: :nullify

  validates :name, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :norm_hours, numericality: { greater_than: 0 }, allow_nil: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }
  scope :search, ->(query) { query.blank? ? all : where("services.name ILIKE :q OR services.code ILIKE :q", q: like_pattern(query)) }

  def label
    code.present? ? "#{code} · #{name}" : name
  end
end
