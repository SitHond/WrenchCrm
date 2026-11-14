class Payment < ApplicationRecord
  enum :payment_method, { cash: 0, card: 1, transfer: 2 }

  belongs_to :work_order
  belongs_to :created_by, class_name: "User", optional: true

  validates :amount, numericality: { other_than: 0 }
  validates :paid_at, presence: true

  before_validation { self.paid_at ||= Time.current }
  before_create { self.created_by ||= Current.user }

  scope :in_period, ->(range) { where(paid_at: range) }
end
