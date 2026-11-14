# Accumulative discount step: once a client has spent `threshold`, they get these discounts.
class LoyaltyTier < ApplicationRecord
  validates :threshold, numericality: { greater_than: 0 }, uniqueness: true
  validates :labor_percent, :parts_percent, numericality: { in: 0..100 }

  scope :ordered, -> { order(:threshold) }

  def self.for_amount(amount)
    ordered.where(threshold: ..amount).last
  end

  def self.next_after(amount)
    ordered.where("threshold > ?", amount).first
  end
end
