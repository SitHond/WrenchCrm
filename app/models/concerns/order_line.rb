module OrderLine
  extend ActiveSupport::Concern

  included do
    belongs_to :work_order

    validates :name, presence: true
    validates :quantity, numericality: { greater_than: 0 }
    validates :price, numericality: { greater_than_or_equal_to: 0 }
    validate :work_order_must_be_editable
  end

  def total
    (quantity * price).round(2)
  end

  private
    def work_order_must_be_editable
      errors.add(:base, :order_locked) if work_order && !work_order.editable?
    end
end
