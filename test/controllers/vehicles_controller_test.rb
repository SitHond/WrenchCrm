require "test_helper"

class VehiclesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:advisor) }

  test "adds a vehicle to a client" do
    get new_vehicle_path(client_id: clients(:petrov).id)
    assert_response :success
    assert_difference(-> { clients(:petrov).vehicles.count }) do
      post vehicles_path, params: { vehicle: { client_id: clients(:petrov).id, make: "lada", model: "Vesta", plate_number: "o111oo77" } }
    end
    assert_equal "О111ОО 77", Vehicle.last.plate_number
    assert_equal "Lada", Vehicle.last.make
  end

  test "show includes service history" do
    get vehicle_path(vehicles(:solaris))
    assert_select "a", text: "№ #{work_orders(:open_order).number}"
  end

  test "form offers catalog suggestions" do
    get new_vehicle_path(client_id: clients(:petrov).id)
    assert_select "datalist#vehicle-makes option[value=?]", "Renault"
    assert_select "datalist#vehicle-colors option[value=?]", "Белый"
  end

  test "search by plate typed in Latin" do
    get vehicles_path(q: "a123bc")
    assert_select "a", text: /Solaris/
  end

  test "index search" do
    get vehicles_path(q: "polo")
    assert_select "a", text: "Volkswagen Polo"
    assert_select "a", text: /Solaris/, count: 0
  end
end
