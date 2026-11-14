# Sale price = cost + percent, where the rule is the one with the highest `cost_from` not above the cost.
# E.g. from 0: +80%, from 500: +50%, from 3000: +30%.
class MarkupRule < ApplicationRecord
  ROUND_TO = 10

  validates :cost_from, numericality: { greater_than_or_equal_to: 0 }, uniqueness: true
  validates :percent, numericality: { greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:cost_from) }

  def self.for_cost(cost)
    ordered.where(cost_from: ..cost).last
  end

  # Rounded up to 10 so prices look like 1 250, not 1 247.37.
  def self.price_for(cost)
    rule = for_cost(cost)
    return unless rule && cost.to_d.positive?

    ((cost.to_d * (100 + rule.percent) / 100) / ROUND_TO).ceil * ROUND_TO
  end
end
