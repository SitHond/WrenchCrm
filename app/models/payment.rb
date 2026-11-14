class Payment < ApplicationRecord
  include CashLedgerEntry

  enum :payment_method, { cash: 0, card: 1, transfer: 2 }

  belongs_to :work_order
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :cash_account

  validates :amount, numericality: { other_than: 0 }
  validates :paid_at, presence: true

  before_validation { self.paid_at ||= Time.current }
  before_validation { self.cash_account ||= CashAccount.default_for(payment_method) }
  before_create { self.created_by ||= Current.user }

  scope :in_period, ->(range) { where(paid_at: range) }

  private
    def cash_operation_attributes
      { cash_account: cash_account, kind: :client_payment, amount: amount, occurred_at: paid_at,
        comment: I18n.t("finance.operation_comments.payment", number: work_order.number) }
    end
end
