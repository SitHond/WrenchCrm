require "test_helper"

class VehiclesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:advisor) }

  test "adds a vehicle to a client" do
    get new_vehicle_path(client_id: clients(:petrov).id)
    assert_response :success
    assert_difference(-> { clients(:petrov).vehicles.count }) do
      post vehicles_path, params: { vehicle: { client_id: clients(:petrov).id, make: "Lada", model: "Vesta", plate_number: "о111оо 77" } }
    end
    assert_equal "О111ОО 77", Vehicle.last.plate_number
  end

  test "show includes service history" do
    get vehicle_path(vehicles(:solaris))
    assert_select "a", text: "№ #{work_orders(:open_order).number}"
  end

  test "index search" do
    get vehicles_path(q: "polo")
    assert_select "a", text: "Volkswagen Polo"
    assert_select "a", text: /Solaris/, count: 0
  end
end
