# Vehicle class or job difficulty with its own service prices (e.g. sedan, SUV, minibus).
class ComplexityLevel < ApplicationRecord
  has_many :service_prices, dependent: :destroy
  has_many :work_orders, dependent: :nullify

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :ordered, -> { order(:position, :name) }
end
