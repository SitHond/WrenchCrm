require "test_helper"

class WorkOrderImprovementsTest < ActiveSupport::TestCase
  setup { @order = work_orders(:open_order) }

  test "two performers split a job for payroll" do
    oleg = Employee.create!(name: "Олег", labor_percent: 50)
    employees(:ivan).update!(labor_percent: 50)
    line = @order.labor_lines.create!(name: "Двигатель", price: 1000, employee: employees(:ivan))
    line.performers.first.update!(share: 50)
    line.performers.create!(employee: oleg, share: 50)
    assert_not line.performers.new(employee: Employee.create!(name: "Третий"), share: 10).valid?, "shares above 100% in total"

    approve_all(@order)
    @order.change_status!(:ready)
    @order.change_status!(:closed)
    assert_equal 250, Payroll.new(employees(:ivan), Date.current).labor_pay
    assert_equal 250, Payroll.new(oleg, Date.current).labor_pay
  end

  test "client-supplied part costs nothing and keeps stock" do
    assert_no_difference -> { parts(:oil).reload.quantity } do
      line = @order.part_lines.create!(part: parts(:oil), quantity: 1, client_supplied: true, price: 999)
      assert_equal 0, line.total
      line.destroy
    end
  end

  test "custom lines can be saved to the catalog" do
    assert_difference -> { Service.count } do
      @order.labor_lines.create!(name: "Замена лампы", price: 300, save_to_catalog: "1")
    end
    assert_difference -> { Part.count } do
      line = @order.part_lines.create!(name: "Лампа H7", price: 250, save_to_catalog: "1")
      assert_equal "Лампа H7", line.part.name
    end
  end

  test "service price depends on the order's complexity level" do
    suv = ComplexityLevel.create!(name: "Внедорожник")
    services(:oil_change).prices.create!(complexity_level: suv, price: 1800)
    @order.update!(complexity_level: suv)
    assert_equal 1800, @order.labor_lines.create!(service: services(:oil_change)).price
    @order.update!(complexity_level: nil)
    assert_equal 1200, @order.labor_lines.create!(service: services(:oil_change)).price
  end

  test "negative stock can be forbidden" do
    ShopSetting.current.update!(allow_negative_stock: false)
    line = @order.part_lines.new(part: parts(:filter), quantity: 2)
    assert_not line.valid?
    assert line.errors.added?(:quantity, :not_enough_stock, available: "1")
    assert @order.part_lines.new(part: parts(:filter), quantity: 2, client_supplied: true).valid?
    assert_not Sale.new(payment_method: :cash, lines_attributes: [ { part_id: parts(:filter).id, quantity: 5 } ]).valid?
  end

  test "total never goes below zero" do
    @order.update!(discount_amount: 1_000_000)
    assert_equal 0, @order.total
  end
end
