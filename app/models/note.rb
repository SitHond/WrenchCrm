class Note < ApplicationRecord
  NOTABLE_TYPES = %w[Client Vehicle WorkOrder Lead].freeze

  belongs_to :notable, polymorphic: true
  belongs_to :author, class_name: "User", optional: true

  validates :body, presence: true
  validates :notable_type, inclusion: { in: NOTABLE_TYPES }

  scope :recent_first, -> { order(created_at: :desc) }
  scope :visible_to, ->(user) { where(private: false).or(where(author: user)) }

  def editable_by?(user)
    user.admin? || author_id == user.id
  end
end
