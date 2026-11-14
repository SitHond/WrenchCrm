class StockMovement < ApplicationRecord
  enum :kind, { receipt: 0, work_order: 1, sale: 2, write_off: 3, inventory: 4, manual: 5 }

  belongs_to :part
  belongs_to :source, polymorphic: true, optional: true
  belongs_to :created_by, class_name: "User", optional: true

  validates :quantity, numericality: { other_than: 0 }

  before_create { self.created_by ||= Current.user }

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }
end
