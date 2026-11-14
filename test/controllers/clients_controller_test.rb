require "test_helper"

class ClientsControllerTest < ActionDispatch::IntegrationTest
  test "viewer can list and search" do
    sign_in_as users(:viewer)
    get clients_path(q: "А123")
    assert_select "a", text: "Петров Алексей"
    get client_path(clients(:petrov))
    assert_response :success
  end

  test "advisor creates a client and continues to the vehicle form" do
    sign_in_as users(:advisor)
    assert_difference(-> { Client.count }) do
      post clients_path, params: { with_vehicle: 1, client: { kind: "individual", last_name: "Сидоров", phone: "+7 900 000-00-00" } }
    end
    assert_redirected_to new_vehicle_path(client_id: Client.last.id)
    assert_equal users(:advisor), Client.last.created_by
  end

  test "viewer cannot create" do
    sign_in_as users(:viewer)
    assert_no_difference(-> { Client.count }) do
      post clients_path, params: { client: { last_name: "X", phone: "1" } }
    end
  end

  test "client with vehicles is not deleted" do
    sign_in_as users(:admin)
    assert_no_difference(-> { Client.count }) { delete client_path(clients(:petrov)) }
    assert_redirected_to client_path(clients(:petrov))
  end
end
