class WorkOrder < ApplicationRecord
  OPEN_STATUSES = %w[accepted in_progress waiting_parts ready].freeze
  TRANSITIONS = {
    "accepted" => %w[in_progress waiting_parts cancelled],
    "in_progress" => %w[waiting_parts ready cancelled],
    "waiting_parts" => %w[in_progress cancelled],
    "ready" => %w[in_progress closed],
    "closed" => [],
    "cancelled" => []
  }.freeze

  enum :status, { accepted: 0, in_progress: 1, waiting_parts: 2, ready: 3, closed: 4, cancelled: 5 }

  belongs_to :client
  belongs_to :vehicle
  belongs_to :mechanic, class_name: "Employee", optional: true
  belongs_to :advisor, class_name: "Employee", optional: true
  belongs_to :complexity_level, optional: true
  belongs_to :created_by, class_name: "User", optional: true
  has_many :labor_lines, class_name: "WorkOrderLabor", dependent: :destroy
  has_many :part_lines, class_name: "WorkOrderPart", dependent: :destroy
  has_many :payments, -> { order(:paid_at) }, dependent: :restrict_with_error
  has_many :notes, as: :notable, dependent: :destroy
  has_one :appointment, dependent: :nullify

  validates :labor_discount_percent, :parts_discount_percent, numericality: { in: 0..100 }
  validates :discount_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :mileage, numericality: { greater_than_or_equal_to: 0, only_integer: true }, allow_nil: true
  validate :vehicle_belongs_to_client

  before_validation :inherit_client_defaults, on: :create
  before_create { self.created_by ||= Current.user }
  before_create { self.advisor ||= Current.user&.employee }
  after_save { vehicle.record_mileage!(mileage) if saved_change_to_mileage? }

  scope :unfinished, -> { where(status: OPEN_STATUSES) }
  scope :recent_first, -> { order(created_at: :desc) }
  scope :search, ->(query) {
    next all if query.blank?

    pattern = "%#{sanitize_sql_like(query.strip)}%"
    number = query.to_s.gsub(/\D/, "")
    plate = "%#{sanitize_sql_like(PlateNumber.normalize(query).to_s)}%"
    scope = joins(:vehicle, :client).where(<<~SQL.squish, q: pattern, p: plate)
      vehicles.plate_number ILIKE :p OR vehicles.plate_number ILIKE :q OR vehicles.vin ILIKE :q OR vehicles.make ILIKE :q OR vehicles.model ILIKE :q
      OR clients.last_name ILIKE :q OR clients.company_name ILIKE :q OR clients.phone ILIKE :q
    SQL
    number.present? && number.length <= 18 ? scope.or(joins(:vehicle, :client).where(id: number.to_i)) : scope
  }

  def number
    id.to_s.rjust(6, "0")
  end

  def editable?
    !closed? && !cancelled?
  end

  def unfinished?
    OPEN_STATUSES.include?(status)
  end

  def next_statuses
    TRANSITIONS.fetch(status)
  end

  def change_status!(new_status)
    new_status = new_status.to_s
    raise ArgumentError, "invalid transition #{status} -> #{new_status}" unless next_statuses.include?(new_status)

    transaction do
      part_lines.each(&:return_to_stock!) if new_status == "cancelled"
      self.completed_at = Time.current if new_status == "ready"
      self.closed_at = Time.current if new_status == "closed"
      update!(status: new_status)
    end
  end

  def labor_total
    labor_lines.sum(&:total)
  end

  def parts_total
    part_lines.sum(&:total)
  end

  def subtotal
    labor_total + parts_total
  end

  def labor_discount
    (labor_total * labor_discount_percent / 100).round(2)
  end

  def parts_discount
    (parts_total * parts_discount_percent / 100).round(2)
  end

  def total_discount
    labor_discount + parts_discount + discount_amount
  end

  def total
    [ subtotal - total_discount, 0 ].max
  end

  def discount_percent=(value)
    self.labor_discount_percent = value
    self.parts_discount_percent = value
  end

  def paid_total
    payments.sum(&:amount)
  end

  def balance
    total - paid_total
  end

  private
    def inherit_client_defaults
      self.client ||= vehicle&.client
      if client && labor_discount_percent.to_d.zero? && parts_discount_percent.to_d.zero?
        self.labor_discount_percent = client.discount_percent
        self.parts_discount_percent = client.discount_percent
      end
      self.mileage ||= vehicle&.mileage
    end

    def vehicle_belongs_to_client
      errors.add(:vehicle, :invalid) if vehicle && client && vehicle.client_id != client_id
    end
end
