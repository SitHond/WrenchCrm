# Who looked at, changed or exported personal data, and who signed in (152-FZ access log).
class AuditEvent < ApplicationRecord
  ACTIONS = %w[
    login login_failed logout
    view create update destroy print export import
    consent_given consent_withdrawn anonymize
    user_update two_factor
  ].freeze

  belongs_to :user, optional: true
  belongs_to :subject, polymorphic: true, optional: true

  validates :action, inclusion: { in: ACTIONS }

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }

  def self.record!(action, subject: nil, user: Current.user, ip: nil, **details)
    create!(action: action.to_s, subject: subject, user: user, ip_address: ip,
            subject_label: subject && AuditEvent.label_for(subject), details: details.compact)
  end

  def self.label_for(subject)
    case subject
    when Client then subject.display_name
    when Vehicle then subject.label
    when WorkOrder then "№ #{subject.number}"
    when User then subject.email_address
    else subject.try(:display_name) || subject.try(:name) || "#{subject.class.name} #{subject.id}"
    end
  end
end
