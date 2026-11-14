require "test_helper"

class StockFinanceControllerTest < ActionDispatch::IntegrationTest
  test "receipt flow: create, add line, post" do
    sign_in_as users(:admin)
    post purchase_receipts_path, params: { purchase_receipt: { supplier_id: suppliers(:autodetal).id, number: "Н-1", received_on: Date.current } }
    receipt = PurchaseReceipt.last
    post purchase_receipt_purchase_receipt_lines_path(receipt), params: { purchase_receipt_line: { part_id: parts(:filter).id, quantity: 5, cost: 400 } }
    post post_purchase_receipt_path(receipt)
    assert receipt.reload.posted?
    assert_equal 6, parts(:filter).reload.quantity
    get purchase_receipt_path(receipt)
    assert_response :success
    get supplier_path(suppliers(:autodetal))
    assert_response :success
  end

  test "part card with write-off and stock count" do
    sign_in_as users(:admin)
    patch write_off_part_path(parts(:oil)), params: { amount: 2, comment: "Брак" }
    patch count_part_path(parts(:oil)), params: { counted: 7 }
    assert_equal 7, parts(:oil).reload.quantity
    get part_path(parts(:oil))
    assert_select "td", text: "Списание"
  end

  test "counter sale" do
    sign_in_as users(:advisor)
    get new_sale_path
    assert_response :success
    post sales_path, params: { sale: { payment_method: "card", lines_attributes: { "0" => { part_id: parts(:oil).id, quantity: 1 }, "1" => { part_id: "", name: "" } } } }
    assert_redirected_to sale_path(Sale.last)
    assert_equal 1, Sale.last.lines.count
  end

  test "finance pages and manual operations" do
    sign_in_as users(:accountant)
    get cash_operations_path
    assert_response :success
    get new_cash_operation_path(kind: "expense")
    assert_response :success
    post cash_operations_path, params: { cash_operation: { kind: "expense", cash_account_id: cash_accounts(:cash).id, amount: "1500", expense_category_id: expense_categories(:rent).id } }
    assert_equal(-1500, cash_accounts(:cash).balance)
    post transfer_cash_operations_path, params: { from_id: cash_accounts(:bank).id, to_id: cash_accounts(:cash).id, amount: 1500 }
    assert_equal 0, cash_accounts(:cash).balance
    get cash_accounts_path
    assert_response :success
  end

  test "payment-generated operations cannot be deleted from the ledger" do
    payment = work_orders(:open_order).payments.create!(amount: 100, payment_method: :cash)
    sign_in_as users(:accountant)
    delete cash_operation_path(payment.cash_operation)
    assert CashOperation.exists?(payment.cash_operation.id)
  end

  test "payroll pages and payout" do
    sign_in_as users(:accountant)
    get payroll_index_path
    assert_select "a", text: "Иван Кузнецов"
    post salary_payouts_path, params: { salary_payout: { employee_id: employees(:ivan).id, amount: 1000, period: Date.current, cash_account_id: cash_accounts(:cash).id } }
    get payroll_path(employees(:ivan), month: Date.current.strftime("%Y-%m"))
    assert_response :success
    assert_match "1 000,00", response.body
  end

  test "reports" do
    sign_in_as users(:accountant)
    [ reports_path, labor_reports_path, parts_reports_path, stock_reports_path ].each do |path|
      get path
      assert_response :success, path
    end
  end

  test "permissions" do
    sign_in_as users(:advisor)
    get cash_operations_path
    assert_redirected_to root_path
    get reports_path
    assert_redirected_to root_path
    assert_no_difference(-> { PurchaseReceipt.count }) do
      post purchase_receipts_path, params: { purchase_receipt: { supplier_id: suppliers(:autodetal).id } }
    end
  end
end
