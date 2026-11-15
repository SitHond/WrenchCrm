class Vehicle < ApplicationRecord
  include Searchable

  belongs_to :client
  has_many :work_orders, -> { order(created_at: :desc) }, dependent: :restrict_with_error
  has_many :notes, as: :notable, dependent: :destroy
  has_many :tasks, as: :subject, dependent: :destroy
  has_many :appointments, dependent: :destroy
  has_many :service_reminders, dependent: :destroy

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

  DEFAULT_KM_PER_DAY = 15_000 / 365.0

  # [date, mileage] readings from work orders, oldest first.
  def mileage_readings
    @mileage_readings ||= work_orders.where.not(mileage: nil).where.not(status: :estimate)
      .reorder(:created_at).pluck(:created_at, :mileage).map { |time, km| [ time.to_date, km ] }
  end

  def km_per_day
    first, last = mileage_readings.first, mileage_readings.last
    return DEFAULT_KM_PER_DAY unless first && last && last[0] > first[0] && last[1] > first[1]

    (last[1] - first[1]).to_f / (last[0] - first[0]).to_i
  end

  def estimated_mileage(on: Date.current)
    date, km = mileage_readings.last || [ updated_at.to_date, mileage ]
    return unless km

    km + ((on - date).to_i.clamp(0..) * km_per_day).round
  end

  # When the vehicle is expected to reach `target` km.
  def date_for_mileage(target)
    date, km = mileage_readings.last || [ updated_at.to_date, mileage ]
    return unless km

    km >= target ? date : date + ((target - km) / km_per_day).ceil
  end

  def record_mileage!(value)
    update_column(:mileage, value) if value.present? && value.to_i > mileage.to_i
  end
end
