require "test_helper"

class AppointmentTest < ActiveSupport::TestCase
  setup { @start = appointments(:morning).starts_at }

  def build(**attrs)
    Appointment.new({ vehicle: vehicles(:polo), starts_at: @start, duration_minutes: 60 }.merge(attrs))
  end

  test "takes client from vehicle and end from duration" do
    appointment = build
    appointment.validate
    assert_equal clients(:taxi), appointment.client
    assert_equal @start + 1.hour, appointment.ends_at
  end

  test "bay cannot be double booked" do
    assert_not build(bay: bays(:lift1), starts_at: @start + 30.minutes).valid?
    assert build(bay: bays(:lift2), starts_at: @start + 30.minutes).valid?
    assert build(bay: bays(:lift1), starts_at: @start + 1.hour).valid?, "back-to-back is fine"
  end

  test "mechanic cannot be double booked" do
    appointment = build(bay: bays(:lift2), mechanic: employees(:ivan))
    assert_not appointment.valid?
    assert appointment.errors.added?(:mechanic, :busy)
  end

  test "cancelled appointments free the slot" do
    appointments(:morning).change_status!(:cancelled)
    assert build(bay: bays(:lift1)).valid?
  end

  test "restoring a cancelled appointment fails when the slot was taken" do
    morning = appointments(:morning)
    morning.change_status!(:cancelled)
    build(bay: bays(:lift1)).save!
    assert_raises(ActiveRecord::RecordInvalid) { morning.change_status!(:scheduled) }
  end

  test "check-in creates a work order" do
    appointment = appointments(:morning)
    order = appointment.check_in!
    assert appointment.arrived?
    assert_equal appointment.vehicle, order.vehicle
    assert_equal employees(:ivan), order.mechanic
    assert_equal "Замена масла", order.complaint
    assert_raises(ArgumentError) { appointment.check_in! }
  end
end
