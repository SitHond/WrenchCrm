class Part < ApplicationRecord
  include Searchable

  UNITS = %w[pcs l kg m set].freeze

  has_many :work_order_parts, dependent: :nullify

  validates :name, presence: true
  validates :unit, inclusion: { in: UNITS }
  validates :cost, :price, :min_quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity, numericality: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }
  scope :low_stock, -> { active.where("parts.quantity <= parts.min_quantity AND parts.min_quantity > 0") }
  scope :search, ->(query) {
    query.blank? ? all : where("parts.name ILIKE :q OR parts.sku ILIKE :q OR parts.brand ILIKE :q", q: like_pattern(query))
  }

  def label
    [ sku, name, brand ].compact_blank.join(" · ")
  end

  def low_stock?
    min_quantity.positive? && quantity <= min_quantity
  end

  def adjust_stock!(delta)
    return if delta.zero?

    self.class.where(id: id).update_all([ "quantity = quantity + ?", delta ])
    reload
  end
end
