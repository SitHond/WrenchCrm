# Counter sale of parts without a work order. Stock and cash move on creation.
class Sale < ApplicationRecord
  include CashLedgerEntry

  enum :payment_method, { cash: 0, card: 1, transfer: 2 }

  belongs_to :client, optional: true
  belongs_to :cash_account
  belongs_to :created_by, class_name: "User", optional: true
  has_many :lines, class_name: "SaleLine", dependent: :destroy, inverse_of: :sale

  accepts_nested_attributes_for :lines, reject_if: ->(attrs) { attrs[:part_id].blank? && attrs[:name].blank? }

  validates :discount_percent, numericality: { in: 0..100 }
  validate :has_lines

  before_validation { self.sold_at ||= Time.current }
  before_validation { self.cash_account ||= CashAccount.default_for(payment_method) }
  before_validation(on: :create) { self.discount_percent = client.parts_discount if client && discount_percent.to_d.zero? }
  before_create { self.created_by ||= Current.user }
  after_create { lines.each { |line| line.part&.adjust_stock!(-line.quantity, kind: :sale, source: self) } unless Current.importing }
  before_destroy(prepend: true) { lines.each { |line| line.part&.adjust_stock!(line.quantity, kind: :sale, source: self) } }

  scope :recent_first, -> { order(sold_at: :desc, id: :desc) }
  scope :in_period, ->(range) { where(sold_at: range) }

  def number
    id.to_s.rjust(6, "0")
  end

  def subtotal
    lines.sum(&:total)
  end

  def discount_amount
    (subtotal * discount_percent / 100).round(2)
  end

  def total
    subtotal - discount_amount
  end

  private
    def has_lines
      errors.add(:lines, :blank) if lines.reject(&:marked_for_destruction?).empty?
    end

    def cash_operation_attributes
      { cash_account: cash_account, kind: :sale, amount: total, occurred_at: sold_at,
        comment: I18n.t("finance.operation_comments.sale", number: number) }
    end
end
