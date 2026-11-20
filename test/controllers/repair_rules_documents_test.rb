require "test_helper"

class RepairRulesDocumentsTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:advisor)
    @order = work_orders(:open_order)
  end

  test "print pages warn about missing requisites until they are filled in" do
    get print_work_order_path(@order)
    assert_select ".print-warning li", minimum: 4
    ShopSetting.current.update!(legal_name: "ООО «Гайка»", inn: "7701234567", ogrn: "1027700000000", address: "Москва")
    advisor = Employee.create!(name: "Марина Орлова", position: :service_advisor)
    @order.update!(promised_at: 1.day.from_now, advisor: advisor)
    get print_work_order_path(@order)
    assert_select ".print-warning", count: 0
    assert_match "Мастер-приёмщик Марина Орлова", response.body
  end

  test "intake form lists customer parts with their stated value" do
    post work_order_work_order_parts_path(@order), params: { work_order_part: { name: "Колодки клиента", quantity: 1, price: 3500, client_supplied: "1" } }
    line = @order.part_lines.find_by!(name: "Колодки клиента")
    assert_equal 0, line.price
    assert_equal 3500, line.client_value
    get print_work_order_path(@order, doc: "acceptance")
    assert_match "Колодки клиента", response.body
    assert_match "3 500,00", response.body
  end

  test "engine and body numbers and replaced parts appear on documents" do
    vehicles(:solaris).update!(engine_number: "g4fc123456", body_number: "")
    @order.update!(replaced_parts: :returned)
    get print_work_order_path(@order, doc: "act")
    assert_match "G4FC123456", response.body
    assert_match "Возвращены заказчику", response.body
    assert_no_match "Номер кузова", response.body
  end

  test "price list" do
    get price_list_services_path
    assert_match "Прейскурант", response.body
    assert_match "Замена масла", response.body
  end
end
