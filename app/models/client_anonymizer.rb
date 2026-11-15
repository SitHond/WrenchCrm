# Removes a client's personal data while keeping work orders, totals and payments
# that accounting law requires to keep (152-FZ art. 21, 402-FZ art. 29).
class ClientAnonymizer
  def initialize(client, reason:)
    @client = client
    @reason = reason
  end

  def run!
    Client.transaction do
      label = I18n.t("privacy.anonymized_label", id: @client.id, locale: :ru)
      @client.consents.active.each { |consent| consent.withdraw!(@reason) }
      @client.notes.delete_all
      @client.tasks.open.delete_all
      vehicles = @client.vehicles.to_a
      vehicles.each do |vehicle|
        vehicle.notes.delete_all
        vehicle.update_columns(plate_number: nil, vin: nil, updated_at: Time.current)
        vehicle.service_reminders.active.update_all(status: ServiceReminder.statuses[:dismissed], updated_at: Time.current)
      end
      @client.leads.each do |lead|
        lead.notes.delete_all
        lead.update_columns(name: nil, phone: "—", updated_at: Time.current)
      end
      AuditEvent.where(subject: @client).update_all(subject_label: label)
      vehicles.each { |vehicle| AuditEvent.where(subject: vehicle).update_all(subject_label: vehicle.title) }
      @client.update_columns(kind: Client.kinds[:individual], last_name: label, first_name: nil, middle_name: nil, company_name: nil,
                             phone: nil, phone2: nil, email: nil, address: nil, inn: nil,
                             anonymized_at: Time.current, anonymized_by_id: Current.user&.id, updated_at: Time.current)
      AuditEvent.record!(:anonymize, subject: @client, reason: @reason)
    end
  end

  # Clients with no work order, sale or appointment for longer than the retention period.
  def self.inactive_clients(years)
    cutoff = years.years.ago
    Client.where(anonymized_at: nil).where(created_at: ...cutoff)
      .where.not(id: WorkOrder.where(created_at: cutoff..).select(:client_id))
      .where.not(id: Sale.where(sold_at: cutoff..).where.not(client_id: nil).select(:client_id))
      .where.not(id: Appointment.where(starts_at: cutoff..).select(:client_id))
  end
end
