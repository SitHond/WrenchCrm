require "test_helper"

class ClientAnonymizerTest < ActiveSupport::TestCase
  setup { Current.session = users(:admin).sessions.create! }

  test "removes personal data everywhere and keeps documents" do
    client = clients(:petrov)
    client.consents.create!(kind: :personal_data)
    lead = Lead.create!(phone: client.phone, name: "Алексей")
    Task.create!(title: "Позвонить Петрову", subject: client)
    AuditEvent.record!(:view, subject: client)
    total = work_orders(:open_order).total

    client.anonymize!(reason: "Отзыв согласия")
    client.reload
    assert client.anonymized?
    assert_equal "Обезличен ##{client.id}", client.display_name
    assert_nil client.phone
    assert_empty client.notes
    assert_empty client.tasks.open
    assert_not client.personal_data_consent?
    assert_nil vehicles(:solaris).reload.plate_number
    assert_nil vehicles(:solaris).vin
    assert_equal "—", lead.reload.phone
    assert_nil lead.name
    assert_not AuditEvent.where(subject: client).where("subject_label ILIKE ?", "%Петров%").exists?
    assert AuditEvent.exists?(action: "anonymize", subject: client)
    assert_equal total, work_orders(:open_order).reload.total
    assert_equal client, work_orders(:open_order).client
  end

  test "inactive clients are found by the retention period" do
    old = Client.create!(last_name: "Старый", phone: "1", created_at: 6.years.ago)
    recent = Client.create!(last_name: "Недавний", phone: "2", created_at: 6.years.ago)
    recent.vehicles.create!(make: "Lada", model: "Vesta").then { |v| WorkOrder.create!(vehicle: v) }
    inactive = ClientAnonymizer.inactive_clients(5)
    assert_includes inactive, old
    assert_not_includes inactive, recent
    assert_not_includes inactive, clients(:petrov), "created recently"
  end
end
