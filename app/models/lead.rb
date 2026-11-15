# An inquiry from a potential or returning client, tracked until they come in or decline.
class Lead < ApplicationRecord
  OPEN_STATUSES = %w[fresh in_progress booked].freeze

  enum :status, { fresh: 0, in_progress: 1, booked: 2, won: 3, lost: 4 }
  enum :channel, { call: 0, walk_in: 1, website: 2, messenger: 3, referral: 4, other: 5 }, prefix: true

  belongs_to :client, optional: true
  belongs_to :ad_source, optional: true
  belongs_to :assignee, class_name: "User", optional: true
  belongs_to :appointment, optional: true
  belongs_to :work_order, optional: true
  belongs_to :created_by, class_name: "User", optional: true
  has_many :tasks, as: :subject, dependent: :destroy
  has_many :notes, as: :notable, dependent: :destroy

  normalizes :phone, with: ->(phone) { phone.strip }

  validates :phone, presence: true
  validates :lost_reason, presence: true, if: :lost?

  before_validation :match_client, on: :create
  before_create { self.created_by ||= Current.user }
  before_create { self.assignee ||= Current.user }

  scope :open, -> { where(status: OPEN_STATUSES) }
  scope :recent_first, -> { order(created_at: :desc) }
  scope :to_contact, ->(date = Date.current) { open.where(next_contact_on: ..date) }

  def display_name
    name.presence || client&.display_name || phone
  end

  # Called when the booked client arrives and a work order is opened.
  def self.mark_won!(appointment, work_order)
    where(appointment: appointment).where.not(status: :won).find_each do |lead|
      lead.update!(status: :won, work_order: work_order)
    end
  end

  def book!(appointment)
    update!(status: :booked, appointment: appointment, client: appointment.client)
  end

  private
    def match_client
      return if client || phone.blank?

      digits = phone.gsub(/\D/, "").last(10)
      return if digits.length < 10

      self.client = Client.where("RIGHT(regexp_replace(phone, '\\D', '', 'g'), 10) = ?", digits)
        .or(Client.where("RIGHT(regexp_replace(COALESCE(phone2, ''), '\\D', '', 'g'), 10) = ?", digits)).first
      self.ad_source ||= client&.ad_source
    end
end
