# Keeps one CashOperation in sync with a record that moves money (payment, sale, salary payout).
module CashLedgerEntry
  extend ActiveSupport::Concern

  included do
    has_one :cash_operation, as: :source, dependent: :destroy
    after_save :sync_cash_operation
  end

  private
    def sync_cash_operation
      operation = cash_operation || build_cash_operation
      operation.update!(cash_operation_attributes)
    end
end
