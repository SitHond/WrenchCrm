require "test_helper"

class WarrantyTest < ActiveSupport::TestCase
  setup do
    services(:oil_change).update!(warranty_months: 6, warranty_km: 10_000)
    @order = WorkOrder.create!(vehicle: vehicles(:polo), mileage: 100_000)
  end

  test "lines copy warranty from the catalog and stay under warranty until date or mileage passes" do
    line = @order.labor_lines.create!(service: services(:oil_change))
    assert_equal [ 6, 10_000 ], [ line.warranty_months, line.warranty_km ]
    @order.change_status!(:in_progress)
    @order.change_status!(:ready)
    @order.change_status!(:closed)
    line.reload
    assert line.under_warranty?
    assert_equal Date.current.advance(months: 6), line.warranty_until
    assert_equal 110_000, line.warranty_until_km
    assert_includes vehicles(:polo).active_warranties, line
    assert_not line.under_warranty?(on: Date.current.advance(months: 7))
  end

  test "warranty claim must be for the same vehicle" do
    claim = WorkOrder.new(vehicle: vehicles(:polo), warranty_of: work_orders(:closed_order))
    assert_not claim.valid?
    claim.warranty_of = @order
    assert claim.valid?
  end
end
