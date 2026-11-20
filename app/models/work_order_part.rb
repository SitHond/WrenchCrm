class WorkOrderPart < ApplicationRecord
  include OrderLine

  belongs_to :part, optional: true

  attr_accessor :save_to_catalog

  validate :enough_stock, on: :create

  before_validation :copy_from_part, on: :create
  # A customer's own part costs nothing in the order; what they paid for it goes to the intake form.
  before_validation do
    if client_supplied?
      self.client_value = price if client_value.blank? && price.to_d.positive?
      self.price = 0
    end
  end
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

  # Client-supplied parts, lines of an estimate and imported history never touch our stock.
  def stock_part
    part unless client_supplied? || work_order&.estimate? || Current.importing
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
      self.warranty_months ||= part.warranty_months
      self.warranty_km ||= part.warranty_km
      self.price = part.price if price.blank? || price.zero?
    end
end
