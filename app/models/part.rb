class Part < ApplicationRecord
  include Searchable

  UNITS = %w[pcs l kg m set].freeze

  has_many :work_order_parts, dependent: :nullify
  has_many :stock_movements, dependent: :delete_all
  has_many :purchase_receipt_lines, dependent: :restrict_with_error
  has_many :part_analogs, dependent: :destroy
  has_many :analogs, through: :part_analogs

  validates :name, presence: true

  after_create { stock_movements.create!(quantity: quantity, kind: :manual) if quantity.nonzero? }
  validates :unit, inclusion: { in: UNITS }
  validates :cost, :price, :min_quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity, numericality: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }
  scope :low_stock, -> { active.where("parts.quantity <= parts.min_quantity AND parts.min_quantity > 0") }
  scope :search, ->(query) {
    query.blank? ? all : where("parts.name ILIKE :q OR parts.sku ILIKE :q OR parts.brand ILIKE :q OR parts.oem ILIKE :q OR parts.location ILIKE :q", q: like_pattern(query))
  }

  def label
    [ sku, name, brand ].compact_blank.join(" · ")
  end

  def low_stock?
    min_quantity.positive? && quantity <= min_quantity
  end

  def adjust_stock!(delta, kind:, source: nil, comment: nil)
    delta = delta.to_d
    return if delta.zero?

    transaction do
      self.class.where(id: id).update_all([ "quantity = quantity + ?", delta ])
      stock_movements.create!(quantity: delta, kind: kind, source: source, comment: comment)
    end
    reload
  end

  # Weighted average cost after receiving `quantity` at `unit_cost`.
  def receive!(quantity, unit_cost, source:)
    on_hand = [ self.quantity, 0 ].max
    new_cost = on_hand + quantity > 0 ? ((on_hand * cost) + (quantity * unit_cost)) / (on_hand + quantity) : unit_cost
    update_column(:cost, new_cost.round(2))
    adjust_stock!(quantity, kind: :receipt, source: source)
  end

  def set_quantity!(counted, comment: nil)
    adjust_stock!(counted.to_d - quantity, kind: :inventory, comment: comment)
  end

  def stock_value
    [ quantity, 0 ].max * cost
  end

  def all_analogs
    Part.where(id: PartAnalog.where(part_id: id).select(:analog_id))
      .or(Part.where(id: PartAnalog.where(analog_id: id).select(:part_id)))
  end
end
