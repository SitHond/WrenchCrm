require "test_helper"

class DataImportsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "upload, map, preview and run" do
    get data_imports_path
    assert_response :success
    post data_imports_path, params: { kind: "parts", file: fixture_file_upload("parts_cp1251.csv", "text/csv") }
    record = DataImport.last
    assert_redirected_to data_import_path(record)
    get data_import_path(record)
    assert_select "select#mapping_name option[selected]", text: "Наименование"
    patch data_import_path(record), params: { mode: "skip", mapping: record.effective_mapping, run: "1" }
    assert_equal "done", record.reload.status
    get errors_data_import_path(record)
    assert_match "NO-NAME", response.body
  end

  test "required mapping is enforced" do
    post data_imports_path, params: { kind: "parts", file: fixture_file_upload("parts_cp1251.csv", "text/csv") }
    record = DataImport.last
    patch data_import_path(record), params: { mode: "skip", mapping: { "sku" => "1" }, run: "1" }
    assert_equal "uploaded", record.reload.status
    assert_match "Наименование", flash[:alert]
  end

  test "templates, S+ upload and full export" do
    get template_data_imports_path("clients")
    assert_match "Госномер", response.body
    post splus_data_imports_path, params: { files: %w[splus_orders.csv splus_labor.csv splus_parts.csv].map { |f| fixture_file_upload(f, "text/csv") } }
    assert WorkOrder.exists?(900001)
    get data_import_path(DataImport.last)
    assert_match "заказ-нарядов", response.body
    get full_export_path
    assert_equal "application/zip", response.media_type
    entries = Zip::File.open_buffer(StringIO.new(response.body)).entries.map(&:name)
    assert_includes entries, "clients.csv"
    assert_includes entries, "work_order_lines.csv"
  end

  test "admin only" do
    sign_in_as users(:advisor)
    get data_imports_path
    assert_redirected_to root_path
  end
end
