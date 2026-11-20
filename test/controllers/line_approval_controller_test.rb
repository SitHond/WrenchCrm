require "test_helper"

class LineApprovalControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:advisor)
    @order = work_orders(:open_order)
  end

  test "extra line is flagged, approved from the order page and printed only after approval" do
    post work_order_work_order_labors_path(@order), params: { work_order_labor: { name: "Замена ШРУС", price: 5000 } }
    line = @order.labor_lines.find_by!(name: "Замена ШРУС")
    get work_order_path(@order)
    assert_match "ждут согласования", response.body
    get print_work_order_path(@order, doc: "act")
    assert_no_match "Замена ШРУС", response.body

    patch status_work_order_path(@order, status: "ready")
    assert_match "несогласованные", flash[:alert]
    assert @order.reload.in_progress?

    patch approve_work_order_work_order_labor_path(@order, line), params: { approval_method: "" }
    assert_not line.reload.approved?
    patch approve_work_order_work_order_labor_path(@order, line), params: { approval_method: "phone", approval_note: "Согласен, звонок 14:20" }
    assert line.reload.approved_phone?
    assert AuditEvent.exists?(action: "update", subject: @order)
    get print_work_order_path(@order, doc: "act")
    assert_match "Замена ШРУС", response.body
  end
end
