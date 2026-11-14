require "test_helper"

class FinanceTest < ActiveSupport::TestCase
  test "payment lands on the account for its method and in the ledger" do
    payment = work_orders(:open_order).payments.create!(amount: 1000, payment_method: :card)
    assert_equal cash_accounts(:bank), payment.cash_account
    assert_equal 1000, cash_accounts(:bank).balance
    payment.update!(amount: 1200)
    assert_equal 1200, cash_accounts(:bank).balance
    payment.destroy
    assert_equal 0, cash_accounts(:bank).balance
  end

  test "cash payment goes to the cash desk" do
    payment = work_orders(:open_order).payments.create!(amount: 500, payment_method: :cash)
    assert_equal cash_accounts(:cash), payment.cash_account
  end

  test "default account is created when missing" do
    CashAccount.where(kind: :cash).delete_all
    account = CashAccount.default_for(:cash)
    assert account.cash?
  end

  test "counter sale moves stock and money, deleting it reverts both" do
    sale = Sale.create!(payment_method: :cash, client: clients(:taxi), lines_attributes: [ { part_id: parts(:oil).id, quantity: 2 } ])
    assert_equal 8, parts(:oil).reload.quantity
    assert_equal 10, sale.discount_percent, "client discount"
    assert_equal 6840, sale.total
    assert_equal 6840, cash_accounts(:cash).balance
    sale.destroy
    assert_equal 10, parts(:oil).reload.quantity
    assert_equal 0, cash_accounts(:cash).balance
  end

  test "sale needs at least one line" do
    assert_not Sale.new(payment_method: :cash).valid?
  end

  test "transfer moves money between accounts and is deleted as a pair" do
    outgoing, _incoming = CashOperation.transfer!(from: cash_accounts(:cash), to: cash_accounts(:bank), amount: 300)
    assert_equal(-300, cash_accounts(:cash).balance)
    assert_equal 300, cash_accounts(:bank).balance
    outgoing.destroy
    assert_equal 0, CashOperation.transfer.count
  end

  test "supplier payment requires a supplier" do
    assert_not CashOperation.new(kind: :supplier_payment, cash_account: cash_accounts(:bank), amount: -1).valid?
  end
end
