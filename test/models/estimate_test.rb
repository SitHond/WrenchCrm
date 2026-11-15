require "test_helper"

class EstimateTest < ActiveSupport::TestCase
  setup { @estimate = WorkOrder.create!(vehicle: vehicles(:polo), status: :estimate) }

  test "estimate lines do not touch stock until approved" do
    assert_no_difference -> { parts(:oil).reload.quantity } do
      line = @estimate.part_lines.create!(part: parts(:oil), quantity: 3)
      line.update!(quantity: 4)
    end
    assert_difference -> { parts(:oil).reload.quantity }, -4 do
      @estimate.change_status!(:accepted)
    end
    assert @estimate.reload.accepted?
  end

  test "declined estimate returns nothing because nothing was taken" do
    @estimate.part_lines.create!(part: parts(:oil), quantity: 2)
    assert_no_difference -> { parts(:oil).reload.quantity } do
      @estimate.change_status!(:cancelled)
    end
  end

  test "approval stops on shortage when negative stock is off" do
    ShopSetting.current.update!(allow_negative_stock: false)
    @estimate.part_lines.create!(part: parts(:filter), quantity: 5)
    error = assert_raises(WorkOrder::StockShortage) { @estimate.change_status!(:accepted) }
    assert_equal [ "Фильтр масляный" ], error.lines.map(&:name)
    assert @estimate.reload.estimate?
    assert_equal 1, parts(:filter).reload.quantity
  end

  test "estimates are not open orders" do
    assert_not_includes WorkOrder.unfinished, @estimate
  end
end
