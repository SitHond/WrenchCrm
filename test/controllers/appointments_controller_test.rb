require "test_helper"

class AppointmentsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:advisor) }

  test "calendar shows bays and appointments" do
    get appointments_path(date: appointments(:morning).starts_at.to_date)
    assert_response :success
    assert_select ".calendar-head", text: "Подъёмник 1"
    assert_select ".calendar-event", text: /Hyundai Solaris/
  end

  test "books from a calendar slot" do
    starts = appointments(:morning).starts_at.change(hour: 15)
    get new_appointment_path(starts_at: starts.iso8601, bay_id: bays(:lift2).id)
    assert_response :success

    assert_difference(-> { Appointment.count }) do
      post appointments_path, params: { appointment: {
        vehicle_id: vehicles(:polo).id, bay_id: bays(:lift2).id, date: starts.to_date.iso8601,
        time: "15:00", duration_minutes: 90, description: "ТО"
      } }
    end
    appointment = Appointment.last
    assert_equal starts, appointment.starts_at
    assert_equal 90, appointment.duration
    assert_redirected_to appointments_path(date: starts.to_date)
  end

  test "conflicting booking re-renders the form" do
    morning = appointments(:morning)
    post appointments_path, params: { appointment: {
      vehicle_id: vehicles(:polo).id, bay_id: bays(:lift1).id, date: morning.starts_at.to_date.iso8601,
      time: "10:30", duration_minutes: 60
    } }
    assert_response :unprocessable_entity
  end

  test "check-in redirects to the new work order" do
    assert_difference(-> { WorkOrder.count }) { post check_in_appointment_path(appointments(:morning)) }
    assert_redirected_to work_order_path(WorkOrder.last)
  end

  test "status change and show page" do
    patch status_appointment_path(appointments(:morning), status: "confirmed")
    assert appointments(:morning).reload.confirmed?
    get appointment_path(appointments(:morning))
    assert_response :success
  end

  test "viewer can see the calendar but not book" do
    sign_in_as users(:viewer)
    get appointments_path
    assert_response :success
    assert_no_difference(-> { Appointment.count }) do
      post appointments_path, params: { appointment: { vehicle_id: vehicles(:polo).id, date: Date.tomorrow.iso8601, time: "12:00", duration_minutes: 60 } }
    end
  end

  test "admin manages bays" do
    sign_in_as users(:admin)
    assert_difference(-> { Bay.count }) { post admin_bays_path, params: { bay: { name: "Мойка", position: 3 } } }
    get admin_bays_path
    assert_select "td", text: "Мойка"
  end
end
