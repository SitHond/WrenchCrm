class WorkOrderPart < ApplicationRecord
  include OrderLine

  belongs_to :part, optional: true

  attr_accessor :save_to_catalog

  validate :enough_stock, on: :create

  before_validation :copy_from_part, on: :create
  before_validation { self.price = 0 if client_supplied? }
  before_create :create_catalog_part, if: -> { save_to_catalog.to_s == "1" && part.nil? && !client_supplied? }
  after_create { stock_part&.adjust_stock!(-quantity, kind: :work_order, source: work_order) }
  after_update { stock_part&.adjust_stock!(quantity_before_last_save - quantity, kind: :work_order, source: work_order) if saved_change_to_quantity? }
  after_destroy { stock_part&.adjust_stock!(quantity, kind: :work_order, source: work_order) if work_order.editable? }

  def return_to_stock!
    stock_part&.adjust_stock!(quantity, kind: :work_order, source: work_order)
  end

  def take_from_stock!
    part&.adjust_stock!(-quantity, kind: :work_order, source: work_order) unless client_supplied?
  end

  # Client-supplied parts and lines of an estimate never touch our stock.
  def stock_part
    part unless client_supplied? || work_order&.estimate?
  end

  def margin
    total - (quantity * cost)
  end

  private
    def enough_stock
      return unless stock_part && !ShopSetting.current.allow_negative_stock && quantity

      errors.add(:quantity, :not_enough_stock, available: stock_part.quantity.to_s("F").sub(/\.0\z/, "")) if quantity > stock_part.quantity
    end

    def create_catalog_part
      self.part = Part.create!(name: name, price: price)
    end

    def copy_from_part
      return unless part

      self.name = part.label if name.blank?
      self.cost = part.cost
      self.price = part.price if price.blank? || price.zero?
    end
end
