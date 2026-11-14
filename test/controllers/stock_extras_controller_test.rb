require "test_helper"

class StockExtrasControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "reorder report creates a draft receipt" do
    get reorder_reports_path
    assert_select "a", text: /Фильтр масляный/
    post from_reorder_purchase_receipts_path, params: { supplier_id: suppliers(:autodetal).id,
      items: { "0" => { part_id: parts(:filter).id, selected: "1", quantity: "9", cost: "420" }, "1" => { part_id: parts(:oil).id, quantity: "1", cost: "1" } } }
    receipt = PurchaseReceipt.last
    assert_redirected_to purchase_receipt_path(receipt)
    assert receipt.draft?
    assert_equal [ parts(:filter) ], receipt.lines.map(&:part)
  end

  test "categories and markup rules from settings" do
    post catalog_categories_path, params: { catalog_category: { name: "Фильтры", kind: "part" } }
    category = CatalogCategory.part.find_by!(name: "Фильтры")
    patch part_path(parts(:filter)), params: { part: { category_id: category.id } }
    get parts_path(category_id: category.id)
    assert_select "a", text: "Фильтр масляный"
    assert_select "a", text: "Масло 5W-30", count: 0
    post markup_rules_path, params: { markup_rule: { cost_from: 0, percent: 60 } }
    get edit_shop_settings_path
    assert_match "+60%", response.body
  end
end
