# "Change the oil by 2027-03 or 105 000 km": who to call and when.
class ServiceReminder < ApplicationRecord
  LEAD_DAYS = 14
  ACTIVE_STATUSES = %w[pending contacted booked].freeze

  enum :status, { pending: 0, contacted: 1, booked: 2, done: 3, dismissed: 4 }

  belongs_to :vehicle
  belongs_to :service, optional: true
  belongs_to :source_work_order, class_name: "WorkOrder", optional: true
  belongs_to :created_by, class_name: "User", optional: true

  validates :title, presence: true
  validates :due_mileage, numericality: { greater_than: 0, only_integer: true }, allow_nil: true
  validate :due_date_or_mileage

  before_create { self.created_by ||= Current.user }

  scope :active, -> { where(status: ACTIVE_STATUSES) }
  scope :awake, -> { where(snoozed_until: nil).or(where(snoozed_until: ..Date.current)) }

  delegate :client, to: :vehicle

  # Created when a work order is handed over, from services that have a reminder interval.
  def self.create_from_work_order!(order)
    order.labor_lines.includes(:service).each do |line|
      service = line.service
      next unless service && (service.reminder_months || service.reminder_km)

      order.vehicle.service_reminders.active.where(service: service).update_all(status: statuses[:done], updated_at: Time.current)
      order.vehicle.service_reminders.create!(
        service: service, title: service.name, source_work_order: order, created_by: order.created_by,
        due_on: service.reminder_months && (order.closed_at || Time.current).to_date.advance(months: service.reminder_months),
        due_mileage: service.reminder_km && order.mileage && order.mileage + service.reminder_km
      )
    end
  end

  # Active reminders whose date or estimated mileage comes within LEAD_DAYS.
  def self.due(today: Date.current)
    active.awake.includes(:vehicle).select { |reminder| reminder.due?(today: today) }
  end

  def expected_on
    [ due_on, mileage_reached_on ].compact.min
  end

  def due?(today: Date.current)
    date = expected_on
    date.present? && date <= today + LEAD_DAYS
  end

  def overdue?(today: Date.current)
    expected_on.present? && expected_on < today
  end

  def mileage_reached_on
    return unless due_mileage

    vehicle.date_for_mileage(due_mileage)
  end

  def snooze!(days)
    update!(snoozed_until: Date.current + days.to_i)
  end

  def contacted!(comment = nil)
    update!(status: :contacted, contacted_at: Time.current, comment: comment.presence || self.comment)
  end

  private
    def due_date_or_mileage
      errors.add(:base, :due_date_or_mileage) if due_on.blank? && due_mileage.blank?
    end
end
