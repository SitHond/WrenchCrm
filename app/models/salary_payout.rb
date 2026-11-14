class SalaryPayout < ApplicationRecord
  include CashLedgerEntry

  belongs_to :employee
  belongs_to :cash_account
  belongs_to :created_by, class_name: "User", optional: true

  validates :amount, numericality: { greater_than: 0 }
  validates :period, :paid_on, presence: true

  before_validation { self.period = period&.beginning_of_month }
  before_validation { self.paid_on ||= Date.current }
  before_create { self.created_by ||= Current.user }

  private
    def cash_operation_attributes
      { cash_account: cash_account, kind: :salary, amount: -amount, occurred_at: paid_on.in_time_zone.change(hour: 12),
        employee: employee, comment: I18n.t("finance.operation_comments.salary", name: employee.name, period: MonthLabel.call(period)) }
    end
end
