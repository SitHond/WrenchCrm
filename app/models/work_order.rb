class WorkOrder < ApplicationRecord
  include VatDocument

  class StockShortage < StandardError
    attr_reader :lines

    def initialize(lines)
      @lines = lines
      super("not enough stock for #{lines.map(&:name).join(', ')}")
    end
  end

  class PendingApproval < StandardError; end

  OPEN_STATUSES = %w[accepted in_progress waiting_parts ready].freeze
  TRANSITIONS = {
    "estimate" => %w[accepted cancelled],
    "accepted" => %w[in_progress waiting_parts cancelled],
    "in_progress" => %w[waiting_parts ready cancelled],
    "waiting_parts" => %w[in_progress cancelled],
    "ready" => %w[in_progress closed],
    "closed" => [],
    "cancelled" => []
  }.freeze

  enum :replaced_parts, { not_set: 0, returned: 1, disposed: 2 }, prefix: :replaced_parts
  enum :status, { estimate: 6, accepted: 0, in_progress: 1, waiting_parts: 2, ready: 3, closed: 4, cancelled: 5 }

  belongs_to :client
  belongs_to :vehicle
  belongs_to :mechanic, class_name: "Employee", optional: true
  belongs_to :advisor, class_name: "Employee", optional: true
  belongs_to :complexity_level, optional: true
  belongs_to :warranty_of, class_name: "WorkOrder", optional: true
  has_many :warranty_claims, class_name: "WorkOrder", foreign_key: :warranty_of_id, dependent: :nullify, inverse_of: :warranty_of
  belongs_to :created_by, class_name: "User", optional: true
  has_many :labor_lines, class_name: "WorkOrderLabor", dependent: :destroy
  has_many :part_lines, class_name: "WorkOrderPart", dependent: :destroy
  has_many :payments, -> { order(:paid_at) }, dependent: :restrict_with_error
  has_many :notes, as: :notable, dependent: :destroy
  has_many :tasks, as: :subject, dependent: :destroy
  has_one :appointment, dependent: :nullify

  validates :labor_discount_percent, :parts_discount_percent, numericality: { in: 0..100 }
  validates :discount_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :fuel_level, numericality: { in: 0..100, only_integer: true }, allow_nil: true
  validates :mileage, numericality: { greater_than_or_equal_to: 0, only_integer: true }, allow_nil: true
  validate :vehicle_belongs_to_client
  validate :warranty_of_same_vehicle

  before_validation :inherit_client_defaults, on: :create
  before_create { self.created_by ||= Current.user }
  before_create { self.advisor ||= Current.user&.employee }
  after_save { vehicle.record_mileage!(mileage) if saved_change_to_mileage? }

  # Next number after imported history that kept its original numbers.
  def self.reset_number_sequence!
    connection.execute("SELECT setval(pg_get_serial_sequence('work_orders', 'id'), GREATEST((SELECT MAX(id) FROM work_orders), 1))")
  end

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

  # What ПП № 290 expects on the contract and acts but is missing here.
  def document_problems
    shop = ShopSetting.current
    problems = []
    problems << :shop_name if shop.legal_name.blank? && shop.name.blank?
    problems << :shop_inn if shop.inn.blank?
    problems << :shop_ogrn if shop.ogrn.blank?
    problems << :shop_address if shop.address.blank?
    problems << :client_phone if client.phone.blank?
    problems << :promised_at if promised_at.blank? && !closed?
    problems << :advisor if advisor.blank?
    problems
  end

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

    raise PendingApproval if new_status.in?(%w[ready closed]) && pending_lines.any?

    transaction do
      approve_estimate! if estimate? && new_status == "accepted"
      part_lines.each(&:return_to_stock!) if new_status == "cancelled" && !estimate?
      self.completed_at = Time.current if new_status == "ready"
      self.closed_at = Time.current if new_status == "closed"
      update!(status: new_status)
      ServiceReminder.create_from_work_order!(self) if closed?
    end
  end

  def labor_total
    labor_lines.select(&:approved?).sum(&:total)
  end

  def pending_lines
    labor_lines.reject(&:approved?) + part_lines.reject(&:approved?)
  end

  def pending_total
    pending_lines.sum(&:total)
  end

  def parts_total
    part_lines.select(&:approved?).sum(&:total)
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

  # What the customer pays: priced lines after discounts, plus VAT when it is charged on top.
  def total
    amount = [ subtotal - total_discount, 0 ].max
    vat? && !vat_included ? amount + vat_amount : amount
  end

  def priced_lines
    labor = labor_lines.select(&:approved?).sort_by { |l| [ l.created_at || Time.current, l.id.to_i ] }
    parts = part_lines.select(&:approved?).sort_by { |l| [ l.created_at || Time.current, l.id.to_i ] }
    amounts = labor.map { |l| l.total * (1 - labor_discount_percent / 100) } + parts.map { |l| l.total * (1 - parts_discount_percent / 100) }
    amounts = spread(amounts.map { |a| a.round(2) }, [ discount_amount, amounts.sum ].min)
    lines = labor.map { |l| [ :labor, l.name, "service", l.quantity ] } + parts.map { |l| [ :part, l.name, l.part&.unit || "pcs", l.quantity ] }
    lines.zip(amounts).map { |(kind, name, unit, quantity), amount| [ kind, name, unit, quantity, amount ] }
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
    # The client agreed: parts leave stock now, not while the estimate was being discussed.
    def approve_estimate!
      unless ShopSetting.current.allow_negative_stock
        short = part_lines.includes(:part).select { |line| line.part && !line.client_supplied? && line.quantity > line.part.quantity }
        raise StockShortage, short if short.any?
      end
      update_column(:status, self.class.statuses[:accepted])
      part_lines.includes(:part).each(&:take_from_stock!)
    end

    def inherit_client_defaults
      self.client ||= vehicle&.client
      if client && labor_discount_percent.to_d.zero? && parts_discount_percent.to_d.zero?
        self.labor_discount_percent = client.labor_discount
        self.parts_discount_percent = client.parts_discount
      end
      self.mileage ||= vehicle&.mileage
    end

    def warranty_of_same_vehicle
      errors.add(:warranty_of, :invalid) if warranty_of && (warranty_of.vehicle_id != vehicle_id || warranty_of == self)
    end

    def vehicle_belongs_to_client
      errors.add(:vehicle, :invalid) if vehicle && client && vehicle.client_id != client_id
    end
end
