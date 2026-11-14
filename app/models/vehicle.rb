class Vehicle < ApplicationRecord
  include Searchable

  belongs_to :client
  has_many :work_orders, -> { order(created_at: :desc) }, dependent: :restrict_with_error
  has_many :notes, as: :notable, dependent: :destroy
  has_many :appointments, dependent: :destroy

  normalizes :vin, with: ->(vin) { vin.strip.upcase.presence }
  normalizes :plate_number, with: ->(plate) { PlateNumber.normalize(plate) }
  normalizes :make, with: ->(make) { VehicleCatalog.canonical_make(make) }
  normalizes :model, :color, :engine, with: ->(value) { value.strip.presence }

  validates :make, :model, presence: true
  validates :vin, length: { is: 17 }, format: { with: /\A[A-HJ-NPR-Z0-9]+\z/ }, uniqueness: true, allow_nil: true
  validates :year, numericality: { in: 1900..(Date.current.year + 1), only_integer: true }, allow_nil: true
  validates :mileage, numericality: { greater_than_or_equal_to: 0, only_integer: true }, allow_nil: true

  scope :ordered, -> { order(:make, :model, :plate_number) }
  scope :search, ->(query) {
    next all if query.blank?

    where(<<~SQL.squish, q: like_pattern(query), p: like_pattern(PlateNumber.normalize(query)))
      vehicles.plate_number ILIKE :q OR vehicles.plate_number ILIKE :p OR vehicles.vin ILIKE :q OR vehicles.make ILIKE :q
      OR vehicles.model ILIKE :q OR (vehicles.make || ' ' || vehicles.model) ILIKE :q
    SQL
  }

  def title
    [ make, model, year ].compact_blank.join(" ")
  end

  def label
    [ title, plate_number ].compact_blank.join(", ")
  end

  def record_mileage!(value)
    update_column(:mileage, value) if value.present? && value.to_i > mileage.to_i
  end
end
