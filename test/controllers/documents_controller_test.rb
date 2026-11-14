require "test_helper"

class DocumentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:advisor)
    ShopSetting.current.update!(legal_name: "ООО «Гайка»", inn: "7701234567", bank_name: "Банк", bik: "044525225",
                                bank_account: "40702810900000000001", correspondent_account: "30101810400000000225",
                                work_order_terms: "Гарантия 30 дней")
    @order = work_orders(:open_order)
  end

  test "every document renders with requisites and the amount in words" do
    %w[work_order acceptance act invoice].each do |doc|
      get print_work_order_path(@order, doc: doc)
      assert_response :success, doc
      assert_match "ООО «Гайка»", response.body, doc
    end
    get print_work_order_path(@order, doc: "invoice")
    assert_match "Пять тысяч триста рублей 00 копеек", response.body
    assert_match "40702810900000000001", response.body
    get print_work_order_path(@order)
    assert_match "Гарантия 30 дней", response.body
  end

  test "intake details are saved and printed" do
    patch work_order_path(@order), params: { work_order: { fuel_level: 40, intake_condition: "Скол на стекле", intake_items: "Запаска" } }
    assert_equal 40, @order.reload.fuel_level
    get print_work_order_path(@order, doc: "acceptance")
    assert_match "Скол на стекле", response.body
    assert_match "40%", response.body
  end

  test "unknown document falls back to the work order" do
    get print_work_order_path(@order, doc: "../../etc/passwd")
    assert_response :success
    assert_match "Заказ-наряд № #{@order.number}", response.body
  end
end
