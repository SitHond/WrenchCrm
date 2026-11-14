class Supplier < ApplicationRecord
  include Searchable

  has_many :purchase_receipts, dependent: :restrict_with_error
  has_many :cash_operations, dependent: :restrict_with_error

  validates :name, presence: true
  validates :inn, format: { with: /\A\d{10}(\d{2})?\z/ }, allow_blank: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }
  scope :search, ->(query) { query.blank? ? all : where("suppliers.name ILIKE :q OR suppliers.inn ILIKE :q OR suppliers.phone ILIKE :q", q: like_pattern(query)) }

  def purchased_total
    PurchaseReceiptLine.joins(:purchase_receipt)
      .where(purchase_receipts: { supplier_id: id, status: PurchaseReceipt.statuses[:posted] })
      .sum("purchase_receipt_lines.quantity * purchase_receipt_lines.cost")
  end

  def paid_total
    -cash_operations.supplier_payment.sum(:amount)
  end

  # Positive: we owe the supplier.
  def debt
    purchased_total - paid_total
  end
end
