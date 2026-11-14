class CashAccount < ApplicationRecord
  enum :kind, { cash: 0, bank: 1 }

  has_many :cash_operations, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :name) }

  # Card and bank transfer payments land on the bank account, cash in the cash desk.
  def self.default_for(payment_method)
    kind = payment_method.to_s == "cash" ? :cash : :bank
    active.ordered.find_by(kind: kind) ||
      find_or_create_by!(name: I18n.t("finance.default_accounts.#{kind}", locale: :ru)) { |account| account.kind = kind }
  end

  def balance
    cash_operations.sum(:amount)
  end
end
