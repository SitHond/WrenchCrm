class PurchaseReceiptLine < ApplicationRecord
  belongs_to :purchase_receipt
  belongs_to :part

  validates :quantity, numericality: { greater_than: 0 }
  validates :cost, numericality: { greater_than_or_equal_to: 0 }
  validate :receipt_must_be_draft

  before_validation { self.cost = part.cost if part && cost.nil? }

  def total
    (quantity * cost).round(2)
  end

  private
    def receipt_must_be_draft
      errors.add(:base, :receipt_posted) if purchase_receipt&.posted?
    end
end
