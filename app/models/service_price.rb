class ServicePrice < ApplicationRecord
  belongs_to :service
  belongs_to :complexity_level

  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :complexity_level_id, uniqueness: { scope: :service_id }
end
