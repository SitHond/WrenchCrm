# A to-do for a staff member, optionally about a client, vehicle, work order or lead.
class Task < ApplicationRecord
  SUBJECT_TYPES = %w[Client Vehicle WorkOrder Lead].freeze

  belongs_to :assignee, class_name: "User", optional: true
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :subject, polymorphic: true, optional: true

  validates :title, presence: true
  validates :subject_type, inclusion: { in: SUBJECT_TYPES }, allow_nil: true

  before_create { self.created_by ||= Current.user }
  before_validation { self.assignee ||= Current.user if new_record? }

  scope :open, -> { where(done_at: nil) }
  scope :done, -> { where.not(done_at: nil) }
  scope :due_by, ->(date) { open.where(due_on: ..date) }
  scope :for_user, ->(user) { where(assignee: user) }
  scope :by_due, -> { order(Arel.sql("due_on IS NULL"), :due_on, :created_at) }

  def done?
    done_at.present?
  end

  def overdue?
    !done? && due_on && due_on < Date.current
  end

  def toggle!
    update!(done_at: done? ? nil : Time.current)
  end

  def deletable_by?(user)
    user.admin? || created_by_id == user.id
  end
end
