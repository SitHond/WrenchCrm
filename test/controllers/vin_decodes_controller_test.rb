require "test_helper"

class VinDecodesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:viewer) }

  test "decodes and warns about a known VIN" do
    get vin_decode_path(vin: vehicles(:solaris).vin), as: :json
    data = response.parsed_body
    assert_equal %w[Hyundai Kia], data["makes"]
    assert_equal vehicle_path(vehicles(:solaris)), data.dig("existing", "url")
  end

  test "no warning when editing the same vehicle" do
    get vin_decode_path(vin: vehicles(:solaris).vin, vehicle_id: vehicles(:solaris).id), as: :json
    assert_nil response.parsed_body["existing"]
  end
end
