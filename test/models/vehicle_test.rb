require "test_helper"

class VehicleTest < ActiveSupport::TestCase
  test "normalizes VIN and plate" do
    vehicle = Vehicle.new(vin: " z94ct41dajr654321 ", plate_number: " в001ав  77 ")
    assert_equal "Z94CT41DAJR654321", vehicle.vin
    assert_equal "В001АВ 77", vehicle.plate_number
  end

  test "VIN must be 17 valid characters and unique" do
    vehicle = vehicles(:polo)
    vehicle.vin = "SHORT"
    assert_not vehicle.valid?
    vehicle.vin = "Z94CT41DAJR12345O"
    assert_not vehicle.valid?, "letter O is not allowed in VIN"
    vehicle.vin = vehicles(:solaris).vin
    assert_not vehicle.valid?
    vehicle.vin = ""
    assert vehicle.valid?
  end

  test "mileage only grows" do
    vehicle = vehicles(:solaris)
    vehicle.record_mileage!(80_000)
    assert_equal 90_000, vehicle.reload.mileage
    vehicle.record_mileage!(95_000)
    assert_equal 95_000, vehicle.reload.mileage
  end
end
