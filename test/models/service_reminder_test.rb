require "test_helper"

class ServiceReminderTest < ActiveSupport::TestCase
  setup do
    services(:oil_change).update!(reminder_months: 12, reminder_km: 10_000)
    @vehicle = vehicles(:solaris)
  end

  test "closing a work order creates reminders from service intervals and closes old ones" do
    old = @vehicle.service_reminders.create!(service: services(:oil_change), title: "Старое", due_on: Date.current)
    order = work_orders(:open_order)
    order.labor_lines.create!(service: services(:oil_change))
    approve_all(order)
    order.change_status!(:ready)
    order.change_status!(:closed)
    reminder = @vehicle.service_reminders.active.sole
    assert_equal Date.current.advance(months: 12), reminder.due_on
    assert_equal 100_000, reminder.due_mileage
    assert old.reload.done?
  end

  test "mileage is estimated from visit history" do
    polo = vehicles(:polo)
    travel_to Date.new(2026, 1, 1) do
      WorkOrder.create!(vehicle: polo, mileage: 50_000).update_column(:created_at, Time.zone.local(2025, 1, 1))
      WorkOrder.create!(vehicle: polo, mileage: 60_000).update_column(:created_at, Time.zone.local(2025, 12, 1))
      vehicle = Vehicle.find(polo.id)
      assert_in_delta 10_000 / 334.0, vehicle.km_per_day, 0.01
      assert_in_delta 60_000 + 31 * (10_000 / 334.0), vehicle.estimated_mileage, 2, "31 days since the last visit"
      assert_equal Date.new(2026, 1, 1), vehicle.date_for_mileage(60_900), "900 km at ~30 km a day is 31 days after Dec 1"
    end
  end

  test "due by date or by expected mileage, snoozed ones wait" do
    by_date = @vehicle.service_reminders.create!(title: "Тормоза", due_on: Date.current + 7)
    later = @vehicle.service_reminders.create!(title: "ГРМ", due_on: Date.current + 200)
    by_km = @vehicle.service_reminders.create!(title: "Масло", due_mileage: @vehicle.mileage + 100)
    due = ServiceReminder.due
    assert_includes due, by_date
    assert_includes due, by_km
    assert_not_includes due, later
    by_date.snooze!(30)
    assert_not_includes ServiceReminder.due, by_date
  end

  test "needs a date or mileage" do
    assert_not @vehicle.service_reminders.new(title: "Пусто").valid?
  end
end
