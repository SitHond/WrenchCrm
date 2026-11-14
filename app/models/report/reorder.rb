module Report
  # Parts at or below their minimum stock with a suggested quantity and where we bought them last.
  class Reorder
    Row = Struct.new(:part, :suggested, :last_supplier, :last_cost)

    def rows
      parts = Part.low_stock.includes(:category).ordered.to_a
      last_lines = PurchaseReceiptLine.joins(:purchase_receipt).where(part_id: parts.map(&:id), purchase_receipts: { status: PurchaseReceipt.statuses[:posted] })
        .order("purchase_receipts.received_on", :id).includes(purchase_receipt: :supplier).group_by(&:part_id).transform_values(&:last)
      parts.map do |part|
        line = last_lines[part.id]
        Row.new(part, suggested_quantity(part), line&.purchase_receipt&.supplier, line&.cost || part.cost)
      end
    end

    def suggested_quantity(part)
      # Restock to twice the minimum so the part does not hit the floor again right away.
      ((part.min_quantity * 2) - part.quantity).ceil.clamp(1..)
    end
  end
end
