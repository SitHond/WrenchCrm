class SaleLine < ApplicationRecord
  belongs_to :sale
  belongs_to :part, optional: true

  validates :name, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :price, numericality: { greater_than_or_equal_to: 0 }

  before_validation :copy_from_part, on: :create

  def total
    (quantity * price).round(2)
  end

  def margin
    total - (quantity * cost)
  end

  private
    def copy_from_part
      return unless part

      self.name = part.label if name.blank?
      self.price = part.price if price.blank? || price.zero?
      self.cost = part.cost
    end
end
