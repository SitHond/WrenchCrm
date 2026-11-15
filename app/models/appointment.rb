class Appointment < ApplicationRecord
  DURATIONS = [ 30, 60, 90, 120, 180, 240, 360, 480 ].freeze
  BUSY_STATUSES = %w[scheduled confirmed arrived].freeze
  TRANSITIONS = {
    "scheduled" => %w[confirmed no_show cancelled],
    "confirmed" => %w[no_show cancelled],
    "arrived" => [],
    "no_show" => %w[scheduled],
    "cancelled" => %w[scheduled]
  }.freeze

  enum :status, { scheduled: 0, confirmed: 1, arrived: 2, no_show: 3, cancelled: 4 }

  belongs_to :client
  belongs_to :vehicle
  belongs_to :bay, optional: true
  belongs_to :mechanic, class_name: "Employee", optional: true
  belongs_to :work_order, optional: true
  belongs_to :created_by, class_name: "User", optional: true

  attribute :duration_minutes, :integer

  before_validation :apply_duration
  before_validation { self.client = vehicle&.client }
  before_create { self.created_by ||= Current.user }

  validates :starts_at, :ends_at, presence: true
  validate :ends_after_start
  validate :bay_is_free, :mechanic_is_free, if: :busy?

  scope :busy, -> { where(status: BUSY_STATUSES) }
  scope :on_day, ->(date) { where(starts_at: date.in_time_zone.all_day) }
  scope :overlapping, ->(from, to) { where("appointments.starts_at < ? AND appointments.ends_at > ?", to, from) }
  scope :chronological, -> { order(:starts_at) }
  scope :upcoming, -> { busy.where(ends_at: Time.current..).chronological }

  def duration
    return duration_minutes if duration_minutes
    return unless starts_at && ends_at

    ((ends_at - starts_at) / 60).round
  end

  def busy?
    BUSY_STATUSES.include?(status)
  end

  def next_statuses
    TRANSITIONS.fetch(status)
  end

  def change_status!(new_status)
    new_status = new_status.to_s
    raise ArgumentError, "invalid transition #{status} -> #{new_status}" unless next_statuses.include?(new_status)

    update!(status: new_status)
  end

  def check_in!
    raise ArgumentError, "appointment is not active" unless scheduled? || confirmed?

    transaction do
      order = WorkOrder.create!(vehicle: vehicle, mechanic: mechanic, complaint: description)
      update!(status: :arrived, work_order: order)
      Lead.mark_won!(self, order)
      order
    end
  end

  private
    def apply_duration
      self.ends_at = starts_at + duration_minutes.minutes if starts_at && duration_minutes&.positive?
    end

    def ends_after_start
      errors.add(:ends_at, :after_start) if starts_at && ends_at && ends_at <= starts_at
    end

    def conflicts
      Appointment.busy.overlapping(starts_at, ends_at).where.not(id: id)
    end

    def bay_is_free
      return unless bay && starts_at && ends_at

      errors.add(:bay, :busy) if conflicts.where(bay: bay).exists?
    end

    def mechanic_is_free
      return unless mechanic && starts_at && ends_at

      errors.add(:mechanic, :busy) if conflicts.where(mechanic: mechanic).exists?
    end
end
