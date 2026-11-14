require "test_helper"

class CalendarExportControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "month calendar shows appointments" do
    get calendar_path(month: appointments(:morning).starts_at.strftime("%Y-%m"))
    assert_response :success
    assert_select ".month-item.appointment", minimum: 1
    get calendar_path(month: "garbage")
    assert_response :success
  end

  test "board lists open orders by status and status changes by PATCH" do
    get board_work_orders_path
    assert_select ".board-column[data-status=in_progress] .board-card", count: 1
    patch status_work_order_path(work_orders(:open_order)), params: { status: "ready" }
    assert work_orders(:open_order).reload.ready?
  end

  test "csv exports open in Excel with BOM and semicolons" do
    [ work_orders_path(format: :csv), clients_path(format: :csv), parts_path(format: :csv), cash_operations_path(format: :csv),
      payroll_index_path(format: :csv), reports_path(format: :csv), labor_reports_path(format: :csv), parts_reports_path(format: :csv),
      sources_reports_path(format: :csv), stock_reports_path(format: :csv), reorder_reports_path(format: :csv) ].each do |path|
      get path
      assert_response :success, path
      assert response.body.start_with?("﻿"), path
      assert_equal "text/csv; charset=utf-8", response.media_type + "; charset=" + response.charset, path
    end
    get clients_path(format: :csv)
    assert_match "Петров Алексей;Частное лицо;+7 916 555-12-34", response.body
  end

  test "csv keeps filters" do
    get work_orders_path(format: :csv, status: "closed")
    lines = response.body.lines
    assert_equal 2, lines.size, "header and the closed fixture order"
  end
end
