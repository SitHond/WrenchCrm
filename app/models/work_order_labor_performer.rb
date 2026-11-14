# Employee who did a labor line and their share of it, for payroll (two people half each: 50 / 50).
class WorkOrderLaborPerformer < ApplicationRecord
  belongs_to :work_order_labor
  belongs_to :employee

  validates :share, numericality: { greater_than: 0, less_than_or_equal_to: 100 }
  validates :employee_id, uniqueness: { scope: :work_order_labor_id }
  validate :total_share_within_100

  private
    def total_share_within_100
      others = WorkOrderLaborPerformer.where(work_order_labor_id: work_order_labor_id).where.not(id: id).sum(:share)
      errors.add(:share, :total_exceeded) if others + share.to_d > 100
    end
end
