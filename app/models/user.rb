class User < ApplicationRecord
  PERMISSIONS = %i[add_records edit_records delete_records manage_groups notes].freeze
  LOCALES = %w[ru en].freeze

  has_secure_password
  has_many :sessions, dependent: :destroy
  belongs_to :person, optional: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, presence: true
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :locale, inclusion: { in: LOCALES }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }

  PERMISSIONS.each do |permission|
    define_method(:"can_#{permission}?") { active? && (admin? || public_send(permission)) }
  end

  def record_login!
    update_columns(last_login_at: Time.current, login_count: login_count + 1)
  end
end
