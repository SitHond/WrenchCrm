require "test_helper"

class ServiceRemindersControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:advisor)
    @reminder = vehicles(:solaris).service_reminders.create!(title: "Замена масла", due_on: Date.current)
  end

  test "call list, contacted, snooze, booking marks booked" do
    get service_reminders_path
    assert_match "Замена масла", response.body
    patch contacted_service_reminder_path(@reminder), params: { comment: "Перезвонит в пятницу" }
    assert @reminder.reload.contacted?
    patch snooze_service_reminder_path(@reminder, days: 30)
    assert_equal Date.current + 30, @reminder.reload.snoozed_until
    get new_appointment_path(vehicle_id: vehicles(:solaris).id, service_reminder_id: @reminder.id)
    assert_select "textarea", text: "Замена масла"
    post appointments_path, params: { service_reminder_id: @reminder.id, appointment: {
      vehicle_id: vehicles(:solaris).id, date: Date.tomorrow.iso8601, time: "15:00", duration_minutes: 60 } }
    assert @reminder.reload.booked?
  end

  test "manual reminder from the vehicle page" do
    post service_reminders_path, params: { service_reminder: { vehicle_id: vehicles(:polo).id, title: "ГРМ", due_mileage: 250_000 } }
    assert vehicles(:polo).service_reminders.exists?(title: "ГРМ")
    get vehicle_path(vehicles(:polo))
    assert_match "ГРМ", response.body
  end

  test "viewer sees the list but cannot change it" do
    sign_in_as users(:viewer)
    get service_reminders_path(view: "active")
    assert_response :success
    patch service_reminder_path(@reminder, status: "dismissed")
    assert @reminder.reload.pending?
  end
end
