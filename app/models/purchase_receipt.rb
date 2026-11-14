class PurchaseReceipt < ApplicationRecord
  enum :status, { draft: 0, posted: 1 }

  belongs_to :supplier
  belongs_to :created_by, class_name: "User", optional: true
  has_many :lines, class_name: "PurchaseReceiptLine", dependent: :destroy

  validates :received_on, presence: true

  before_validation { self.received_on ||= Date.current }
  before_create { self.created_by ||= Current.user }

  scope :recent_first, -> { order(received_on: :desc, id: :desc) }

  def total
    lines.sum(&:total)
  end

  def post!
    raise ArgumentError, "already posted" if posted?
    raise ArgumentError, "no lines" if lines.empty?

    transaction do
      lines.includes(:part).each { |line| line.part.receive!(line.quantity, line.cost, source: self) }
      update!(status: :posted, posted_at: Time.current)
    end
  end
end
