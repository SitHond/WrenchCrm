class SaleLine < ApplicationRecord
  belongs_to :sale
  belongs_to :part, optional: true

  validates :name, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validate :enough_stock, on: :create

  before_validation :copy_from_part, on: :create

  def total
    (quantity * price).round(2)
  end

  def margin
    total - (quantity * cost)
  end

  private
    def enough_stock
      return unless part && !ShopSetting.current.allow_negative_stock && quantity

      errors.add(:quantity, :not_enough_stock, available: part.quantity.to_s("F").sub(/\.0\z/, "")) if quantity > part.quantity
    end

    def copy_from_part
      return unless part

      self.name = part.label if name.blank?
      self.price = part.price if price.blank? || price.zero?
      self.cost = part.cost
    end
end
