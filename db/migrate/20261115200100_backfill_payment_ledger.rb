# Existing payments predate cash accounts: put them on default accounts and into the cash ledger.
class BackfillPaymentLedger < ActiveRecord::Migration[8.1]
  def up
    return unless select_value("SELECT 1 FROM payments LIMIT 1")

    now = connection.quote(Time.current)
    cash_id = account_id("Касса", 0, now)
    bank_id = account_id("Расчётный счёт", 1, now)

    execute <<~SQL
      UPDATE payments SET cash_account_id = CASE WHEN payment_method = 0 THEN #{cash_id} ELSE #{bank_id} END
      WHERE cash_account_id IS NULL
    SQL
    execute <<~SQL
      INSERT INTO cash_operations (cash_account_id, kind, amount, occurred_at, source_type, source_id, comment, created_by_id, created_at, updated_at)
      SELECT p.cash_account_id, 0, p.amount, p.paid_at, 'Payment', p.id,
             'Оплата заказ-наряда № ' || LPAD(p.work_order_id::text, 6, '0'), p.created_by_id, #{now}, #{now}
      FROM payments p
      WHERE NOT EXISTS (SELECT 1 FROM cash_operations c WHERE c.source_type = 'Payment' AND c.source_id = p.id)
    SQL
  end

  def down
    execute "DELETE FROM cash_operations WHERE source_type = 'Payment'"
  end

  private
    def account_id(name, kind, now)
      select_value("SELECT id FROM cash_accounts WHERE name = #{connection.quote(name)}") ||
        insert("INSERT INTO cash_accounts (name, kind, position, active, created_at, updated_at) VALUES (#{connection.quote(name)}, #{kind}, #{kind}, true, #{now}, #{now})")
    end
end
