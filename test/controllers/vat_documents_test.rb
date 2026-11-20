require "test_helper"

class VatDocumentsTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:advisor) }

  test "UPD status 2 without VAT and status 1 with VAT" do
    get print_work_order_path(work_orders(:open_order), doc: "upd")
    assert_select ".upd-status", text: "2"
    assert_match "без НДС", response.body

    ShopSetting.current.update!(vat_rate: 22, legal_name: "ООО «Гайка»", inn: "7701234567", kpp: "770101001")
    order = WorkOrder.create!(vehicle: vehicles(:solaris))
    order.labor_lines.create!(name: "Диагностика", price: 1220)
    get print_work_order_path(order, doc: "upd")
    assert_select ".upd-status", text: "1"
    assert_match "220,00", response.body
    assert_match "7701234567 / 770101001", response.body
    get print_work_order_path(order, doc: "invoice")
    assert_match "В т. ч. НДС 22 %", response.body
    get work_order_path(order)
    assert_match "В т. ч. НДС 22 %", response.body
  end

  test "settings set the VAT rate" do
    sign_in_as users(:admin)
    patch shop_settings_path, params: { shop_setting: { vat_rate: "7", vat_included: "1" } }
    assert_equal 7, ShopSetting.current.vat_rate
    patch shop_settings_path, params: { shop_setting: { vat_rate: "" } }
    assert_nil ShopSetting.current.vat_rate
  end
end
