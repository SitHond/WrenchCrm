class Person < ApplicationRecord
  include Addressable
  include AuditedByUser
  include Deactivatable

  enum :gender, { unknown: 0, male: 1, female: 2 }, prefix: true
  enum :family_role, { head_of_household: 1, spouse: 2, child: 3, other_relative: 4, non_relative: 5, unassigned: 0 }
  enum :classification, { member: 1, regular_attender: 2, guest: 3, non_attender: 5, staff: 4, unclassified: 0 }

  belongs_to :family, optional: true
  has_many :group_memberships, dependent: :destroy
  has_many :groups, through: :group_memberships
  has_many :notes, as: :notable, dependent: :destroy
  has_one :user, dependent: :nullify

  validates :first_name, :last_name, presence: true
  validates :email, :work_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :birth_month, inclusion: { in: 1..12 }, allow_nil: true
  validates :birth_day, inclusion: { in: 1..31 }, allow_nil: true
  validates :birth_year, inclusion: { in: 1850..2200 }, allow_nil: true
  validate :birth_date_must_exist

  scope :ordered, -> { order(:last_name, :first_name) }
  scope :search, ->(query) {
    next all if query.blank?

    pattern = "%#{sanitize_sql_like(query.strip)}%"
    where(<<~SQL.squish, q: pattern)
      people.first_name ILIKE :q OR people.last_name ILIKE :q
      OR (people.first_name || ' ' || people.last_name) ILIKE :q
      OR (people.last_name || ' ' || people.first_name) ILIKE :q
      OR people.email ILIKE :q OR people.cell_phone ILIKE :q OR people.home_phone ILIKE :q
    SQL
  }
  scope :with_birthday_in, ->(month) { where(birth_month: month).order(:birth_day) }

  def full_name
    [ title, first_name, middle_name, last_name, suffix ].compact_blank.join(" ")
  end

  def short_name
    "#{first_name} #{last_name}"
  end

  def birth_date
    return unless birth_year && birth_month && birth_day

    Date.new(birth_year, birth_month, birth_day)
  end

  def age(on: Date.current)
    date = birth_date
    return unless date

    on.year - date.year - (on < date.next_year(on.year - date.year) ? 1 : 0)
  end

  def effective_address_lines
    own = address_lines
    own.any? ? own : family&.address_lines.to_a
  end

  def effective_phone
    cell_phone.presence || home_phone.presence || family&.home_phone
  end

  private
    def birth_date_must_exist
      return unless birth_month && birth_day

      Date.new(birth_year || 2000, birth_month, birth_day)
    rescue Date::Error
      errors.add(:birth_day, :invalid)
    end
end
