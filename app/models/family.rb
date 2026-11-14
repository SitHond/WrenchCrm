class Family < ApplicationRecord
  include Addressable
  include AuditedByUser
  include Deactivatable

  has_many :people, -> { order(:family_role, :birth_year, :first_name) }, dependent: :nullify
  has_many :notes, as: :notable, dependent: :destroy

  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  scope :ordered, -> { order(:name) }
  scope :search, ->(query) {
    next all if query.blank?

    pattern = "%#{sanitize_sql_like(query.strip)}%"
    where("families.name ILIKE :q OR families.city ILIKE :q OR families.email ILIKE :q OR families.home_phone ILIKE :q", q: pattern)
  }

  def head
    people.find(&:head_of_household?)
  end
end
