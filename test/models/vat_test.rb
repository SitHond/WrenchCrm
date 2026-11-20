require "test_helper"

class VatTest < ActiveSupport::TestCase
  test "no VAT by default and history keeps its rate" do
    order = WorkOrder.create!(vehicle: vehicles(:polo))
    assert_not order.vat?
    assert_equal 0, order.vat_amount
    ShopSetting.current.update!(vat_rate: 22)
    assert_not order.reload.vat?, "settings never rewrite existing documents"
  end

  test "VAT included in prices, discounts spread over lines" do
    ShopSetting.current.update!(vat_rate: 22, vat_included: true)
    order = WorkOrder.create!(vehicle: vehicles(:polo), labor_discount_percent: 10, discount_amount: 100)
    order.labor_lines.create!(name: "Работа", price: 1220)
    order.part_lines.create!(name: "Деталь", price: 610, quantity: 2)
    order = WorkOrder.find(order.id)
    assert_equal 2218, order.total
    assert_equal [ 1050.63, 1167.37 ], order.vat_lines.map { |l| l.amount.to_f }
    assert_equal 189.46 + 210.51, order.vat_amount.to_f.round(2)
    assert_equal order.total, order.vat_lines.sum(&:amount)
  end

  test "VAT on top raises the total" do
    ShopSetting.current.update!(vat_rate: 22, vat_included: false)
    order = WorkOrder.create!(vehicle: vehicles(:solaris), mileage: 1)
    order.labor_lines.create!(name: "Работа", price: 1000)
    order = WorkOrder.find(order.id)
    assert_equal 220, order.vat_amount
    assert_equal 1220, order.total
  end

  test "counter sale VAT" do
    ShopSetting.current.update!(vat_rate: 5, vat_included: true)
    sale = Sale.create!(payment_method: :cash, lines_attributes: [ { part_id: parts(:oil).id, quantity: 1 } ])
    assert_equal 5, sale.vat_rate
    assert_equal (3800 * 5 / 105.0).round(2), sale.vat_amount.to_f
    assert_equal 3800, sale.total
  end
end
