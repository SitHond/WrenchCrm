require "test_helper"

class LeadTest < ActiveSupport::TestCase
  test "links an existing client by phone in any format" do
    lead = Lead.create!(phone: "8 (916) 555 12 34", request: "ТО")
    assert_equal clients(:petrov), lead.client
    assert_nil Lead.create!(phone: "+7 999 000-00-00").client
  end

  test "lost needs a reason" do
    lead = Lead.create!(phone: "+7 999 000-00-00")
    assert_not lead.update(status: :lost)
    assert lead.update(status: :lost, lost_reason: "Дорого")
  end

  test "booking and arrival move the lead through the funnel" do
    lead = Lead.create!(phone: "+7 916 555-12-34")
    appointment = Appointment.create!(vehicle: vehicles(:solaris), starts_at: 2.days.from_now.change(hour: 10), duration_minutes: 60)
    lead.book!(appointment)
    assert lead.booked?
    order = appointment.check_in!
    assert lead.reload.won?
    assert_equal order, lead.work_order
  end

  test "funnel report counts by source" do
    source = AdSource.create!(name: "Авито")
    Lead.create!(phone: "1", ad_source: source)
    Lead.create!(phone: "2", ad_source: source, status: :won)
    row = Report::Funnel.new(1.day.ago..1.day.from_now).rows.find { |r| r.name == "Авито" }
    assert_equal 2, row.total
    assert_equal 50.0, row.conversion
  end
end
