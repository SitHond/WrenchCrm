class Service < ApplicationRecord
  include Searchable

  belongs_to :category, class_name: "CatalogCategory", optional: true
  has_many :work_order_labors, dependent: :nullify
  has_many :prices, class_name: "ServicePrice", dependent: :destroy

  accepts_nested_attributes_for :prices, reject_if: ->(attrs) { attrs[:price].blank? }, allow_destroy: true

  validates :name, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :norm_hours, numericality: { greater_than: 0 }, allow_nil: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }
  scope :search, ->(query) { query.blank? ? all : where("services.name ILIKE :q OR services.code ILIKE :q", q: like_pattern(query)) }

  # A cleared price removes that level's price; the base price applies again.
  def prices_attributes=(attributes)
    rows = attributes.respond_to?(:values) ? attributes.to_h.values : attributes
    super(rows.map { |row| row = row.to_h.stringify_keys; row["price"].blank? && row["id"].present? ? row.merge("_destroy" => "1") : row })
  end

  def price_for(complexity_level)
    return price unless complexity_level

    prices.find { |p| p.complexity_level_id == complexity_level.id }&.price || price
  end

  def label
    code.present? ? "#{code} · #{name}" : name
  end
end
