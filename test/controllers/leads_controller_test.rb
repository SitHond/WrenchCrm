require "test_helper"

class LeadsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:advisor) }

  test "new lead to client to appointment" do
    post leads_path, params: { lead: { phone: "+7 999 111-22-33", name: "Сидоров", request: "Стук", channel: "call" } }
    lead = Lead.last
    assert_redirected_to lead_path(lead)
    get new_client_path(lead_id: lead.id, with_vehicle: 1)
    assert_select "input[name='client[last_name]'][value=?]", "Сидоров"
    post clients_path, params: { lead_id: lead.id, with_vehicle: 1, client: { kind: "individual", last_name: "Сидоров", phone: "+7 999 111-22-33" } }
    assert_equal Client.last, lead.reload.client
    vehicle = lead.client.vehicles.create!(make: "Kia", model: "Rio")
    post appointments_path, params: { lead_id: lead.id, appointment: { vehicle_id: vehicle.id, date: Date.tomorrow.iso8601, time: "12:00", duration_minutes: 60 } }
    assert lead.reload.booked?
  end

  test "board, move and lost reason" do
    lead = Lead.create!(phone: "+7 999 000-00-01")
    get board_leads_path
    assert_select ".board-column[data-status=fresh] .board-card", count: 1
    patch move_lead_path(lead, status: "in_progress")
    assert lead.reload.in_progress?
    patch move_lead_path(lead, status: "lost")
    assert_redirected_to edit_lead_path(lead, lost: 1)
    patch move_lead_path(lead, status: "lost", lost_reason: "Дорого")
    assert lead.reload.lost?
  end

  test "pages render" do
    lead = Lead.create!(phone: "+7 916 555-12-34", request: "ТО")
    [ leads_path, lead_path(lead), edit_lead_path(lead), new_lead_path, funnel_reports_path ].each do |path|
      sign_in_as users(:admin) if path == funnel_reports_path
      get path
      assert_response :success, path
    end
  end

  test "viewer cannot create leads" do
    sign_in_as users(:viewer)
    assert_no_difference(-> { Lead.count }) { post leads_path, params: { lead: { phone: "1" } } }
  end
end
