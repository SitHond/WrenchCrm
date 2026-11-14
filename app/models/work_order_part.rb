class WorkOrderPart < ApplicationRecord
  include OrderLine

  belongs_to :part, optional: true

  before_validation :copy_from_part, on: :create
  after_create { part&.adjust_stock!(-quantity, kind: :work_order, source: work_order) }
  after_update { part&.adjust_stock!(quantity_before_last_save - quantity, kind: :work_order, source: work_order) if saved_change_to_quantity? }
  after_destroy { part&.adjust_stock!(quantity, kind: :work_order, source: work_order) if work_order.editable? }

  def return_to_stock!
    part&.adjust_stock!(quantity, kind: :work_order, source: work_order)
  end

  def margin
    total - (quantity * cost)
  end

  private
    def copy_from_part
      return unless part

      self.name = part.label if name.blank?
      self.cost = part.cost
      self.price = part.price if price.blank? || price.zero?
    end
end
