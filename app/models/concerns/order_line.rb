module OrderLine
  extend ActiveSupport::Concern

  # Lines added at intake or in an estimate are agreed with the order itself;
  # lines added once work has started need the customer's consent (ПП № 290).
  PRE_AGREED_STATUSES = %w[estimate accepted].freeze

  included do
    belongs_to :work_order
    belongs_to :approved_by, class_name: "User", optional: true

    enum :approval_method, { in_person: 0, phone: 1, message: 2, signature: 3 }, prefix: :approved

    before_create :pre_approve, if: -> { approved_at.nil? && (Current.importing || work_order.status.in?(PRE_AGREED_STATUSES)) }

    scope :approved, -> { where.not(approved_at: nil) }
    scope :pending_approval, -> { where(approved_at: nil) }

    validates :name, presence: true
    validates :quantity, numericality: { greater_than: 0 }
    validates :price, numericality: { greater_than_or_equal_to: 0 }
    validate :work_order_must_be_editable
  end

  def total
    (quantity * price).round(2)
  end

  def approved? = approved_at.present?

  def warranty? = warranty_months.present? || warranty_km.present?

  def warranty_until
    work_order.closed_at&.to_date&.advance(months: warranty_months) if warranty_months
  end

  def warranty_until_km
    work_order.mileage + warranty_km if warranty_km && work_order.mileage
  end

  # Under warranty while neither the date nor the mileage limit has passed.
  def under_warranty?(on: Date.current)
    return false unless warranty? && work_order.closed?

    date_ok = warranty_until.nil? || warranty_until >= on
    km_limit = warranty_until_km
    km_ok = km_limit.nil? || (work_order.vehicle.estimated_mileage || 0) <= km_limit
    date_ok && km_ok
  end

  def approve!(method:, note: nil)
    update_columns(approved_at: Time.current, approval_method: self.class.approval_methods.fetch(method.to_s),
                   approved_by_id: Current.user&.id, approval_note: note.presence, updated_at: Time.current)
  end

  private
    def pre_approve
      self.approved_at = Time.current
    end

    def work_order_must_be_editable
      errors.add(:base, :order_locked) if work_order && !work_order.editable? && !Current.importing
    end
end
