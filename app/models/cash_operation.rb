# One row per money movement. Amount is signed: positive in, negative out.
class CashOperation < ApplicationRecord
  MANUAL_KINDS = %w[expense other_income supplier_payment].freeze

  enum :kind, {
    client_payment: 0, sale: 1, salary: 2, supplier_payment: 3,
    expense: 4, other_income: 5, transfer: 6
  }

  belongs_to :cash_account
  belongs_to :expense_category, optional: true
  belongs_to :supplier, optional: true
  belongs_to :employee, optional: true
  belongs_to :source, polymorphic: true, optional: true
  belongs_to :counterpart, class_name: "CashOperation", optional: true
  belongs_to :created_by, class_name: "User", optional: true

  validates :amount, numericality: { other_than: 0 }
  validates :occurred_at, presence: true
  validates :supplier, presence: true, if: :supplier_payment?

  before_validation { self.occurred_at ||= Time.current }
  before_create { self.created_by ||= Current.user }
  after_destroy { counterpart&.destroy if counterpart&.persisted? }

  scope :recent_first, -> { order(occurred_at: :desc, id: :desc) }
  scope :in_period, ->(range) { where(occurred_at: range) }
  scope :incoming, -> { where("amount > 0") }
  scope :outgoing, -> { where("amount < 0") }

  def self.transfer!(from:, to:, amount:, comment: nil, occurred_at: Time.current)
    transaction do
      outgoing = create!(cash_account: from, kind: :transfer, amount: -amount.to_d.abs, comment: comment, occurred_at: occurred_at)
      incoming = create!(cash_account: to, kind: :transfer, amount: amount.to_d.abs, comment: comment, occurred_at: occurred_at, counterpart: outgoing)
      outgoing.update!(counterpart: incoming)
      [ outgoing, incoming ]
    end
  end

  def manual?
    MANUAL_KINDS.include?(kind) || transfer?
  end
end
