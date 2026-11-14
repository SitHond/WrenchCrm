class Client < ApplicationRecord
  include Searchable

  enum :kind, { individual: 0, company: 1 }

  belongs_to :created_by, class_name: "User", optional: true
  has_many :vehicles, -> { order(:make, :model) }, dependent: :restrict_with_error
  has_many :work_orders, -> { order(created_at: :desc) }, dependent: :restrict_with_error
  has_many :notes, as: :notable, dependent: :destroy
  has_many :appointments, dependent: :destroy

  normalizes :phone, :phone2, with: ->(phone) { phone.strip }
  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :phone, presence: true
  validates :last_name, presence: true, if: :individual?
  validates :company_name, presence: true, if: :company?
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :inn, format: { with: /\A\d{10}(\d{2})?\z/ }, allow_blank: true
  validates :discount_percent, numericality: { in: 0..100 }

  before_create { self.created_by ||= Current.user }

  scope :active, -> { where(deactivated_on: nil) }
  scope :inactive, -> { where.not(deactivated_on: nil) }
  scope :ordered, -> { order(Arel.sql("COALESCE(NULLIF(clients.company_name, ''), clients.last_name)"), :first_name) }
  scope :search, ->(query) {
    next all if query.blank?

    conditions = <<~SQL.squish
      clients.last_name ILIKE :q OR clients.first_name ILIKE :q OR clients.company_name ILIKE :q
      OR (clients.last_name || ' ' || COALESCE(clients.first_name, '')) ILIKE :q
      OR (COALESCE(clients.first_name, '') || ' ' || clients.last_name) ILIKE :q
      OR clients.email ILIKE :q OR clients.inn ILIKE :q
      OR clients.id IN (SELECT client_id FROM vehicles WHERE plate_number ILIKE :q OR plate_number ILIKE :p OR vin ILIKE :q)
    SQL
    digits = digits_pattern(query)
    if digits
      conditions += " OR regexp_replace(clients.phone, '\\D', '', 'g') LIKE :d OR regexp_replace(COALESCE(clients.phone2, ''), '\\D', '', 'g') LIKE :d"
    end
    where(conditions, q: like_pattern(query), p: like_pattern(PlateNumber.normalize(query)), d: digits)
  }

  def display_name
    company? ? company_name : [ last_name, first_name, middle_name ].compact_blank.join(" ")
  end

  def active?
    deactivated_on.nil?
  end
end
