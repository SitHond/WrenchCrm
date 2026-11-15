# Everything a shop needs to move its data elsewhere or back up: one CSV per table.
module FullExport
  module_function

  def files
    {
      "clients.csv" => clients, "parts.csv" => parts, "services.csv" => services, "suppliers.csv" => suppliers,
      "work_orders.csv" => work_orders, "work_order_lines.csv" => work_order_lines, "payments.csv" => payments,
      "cash_operations.csv" => cash_operations
    }
  end

  def labels(definition) = definition.fields.map(&:label)

  def clients
    keys = Imports::Clients.fields.map(&:key)
    rows = Client.includes(:vehicles, :ad_source).find_each.flat_map do |c|
      base = { full_name: (c.individual? ? c.display_name : nil), company_name: c.company_name, phone: c.phone, phone2: c.phone2,
               email: c.email, inn: c.inn, address: c.address, discount_percent: c.discount_percent, ad_source: c.ad_source&.name }
      vehicles = c.vehicles.presence || [ nil ]
      vehicles.map do |v|
        values = base.merge(v ? { make: v.make, model: v.model, year: v.year, plate_number: v.plate_number, vin: v.vin, mileage: v.mileage } : {})
        keys.map { |k| values[k] }
      end
    end
    CsvExport.generate(labels(Imports::Clients), rows)
  end

  def parts
    keys = Imports::Parts.fields.map(&:key)
    rows = Part.includes(:category).order(:name).map do |p|
      values = { name: p.name, sku: p.sku, oem: p.oem, brand: p.brand, category: p.category&.name, unit: I18n.t("parts.units.#{p.unit}"),
                 cost: p.cost, price: p.price, quantity: p.quantity, min_quantity: p.min_quantity, location: p.location }
      keys.map { |k| values[k] }
    end
    CsvExport.generate(labels(Imports::Parts), rows)
  end

  def services
    keys = Imports::Services.fields.map(&:key)
    rows = Service.includes(:category).order(:name).map do |s|
      values = { name: s.name, code: s.code, category: s.category&.name, price: s.price, norm_hours: s.norm_hours,
                 reminder_months: s.reminder_months, reminder_km: s.reminder_km }
      keys.map { |k| values[k] }
    end
    CsvExport.generate(labels(Imports::Services), rows)
  end

  def suppliers
    keys = Imports::Suppliers.fields.map(&:key)
    rows = Supplier.order(:name).map do |s|
      values = { name: s.name, inn: s.inn, phone: s.phone, email: s.email, contact_person: s.contact_person, comment: s.comment }
      keys.map { |k| values[k] }
    end
    CsvExport.generate(labels(Imports::Suppliers), rows)
  end

  def work_orders
    attr = ->(name) { WorkOrder.human_attribute_name(name) }
    headers = [ "№", attr[:created_at], attr[:status], Client.model_name.human, Client.human_attribute_name(:phone), Vehicle.model_name.human,
                Vehicle.human_attribute_name(:plate_number), Vehicle.human_attribute_name(:vin), attr[:mileage], attr[:mechanic], attr[:complaint],
                t_total("labor"), t_total("parts"), attr[:total], t_total("paid"), attr[:closed_at] ]
    rows = WorkOrder.includes(:client, :vehicle, :mechanic, :labor_lines, :part_lines, :payments).order(:id).map do |o|
      [ o.number, o.created_at, I18n.t("activerecord.enums.work_order.status.#{o.status}"), o.client.display_name, o.client.phone,
        o.vehicle.title, o.vehicle.plate_number, o.vehicle.vin, o.mileage, o.mechanic&.name, o.complaint,
        o.labor_total, o.parts_total, o.total, o.paid_total, o.closed_at ]
    end
    CsvExport.generate(headers, rows)
  end

  def work_order_lines
    headers = [ "№", I18n.t("imports.export.line_kind"), WorkOrderLabor.human_attribute_name(:name), WorkOrderLabor.human_attribute_name(:quantity),
                WorkOrderLabor.human_attribute_name(:price), WorkOrderLabor.human_attribute_name(:total), Part.human_attribute_name(:sku) ]
    labor = WorkOrderLabor.order(:work_order_id, :id).map { |l| [ l.work_order_id.to_s.rjust(6, "0"), I18n.t("work_orders.sections.labor"), l.name, l.quantity, l.price, l.total, nil ] }
    parts = WorkOrderPart.includes(:part).order(:work_order_id, :id).map { |l| [ l.work_order_id.to_s.rjust(6, "0"), I18n.t("work_orders.sections.parts"), l.name, l.quantity, l.price, l.total, l.part&.sku ] }
    CsvExport.generate(headers, labor + parts)
  end

  def payments
    headers = [ "№", Payment.human_attribute_name(:amount), Payment.human_attribute_name(:payment_method), CashAccount.model_name.human, Payment.human_attribute_name(:comment), I18n.t("imports.export.paid_at") ]
    rows = Payment.includes(:cash_account).order(:paid_at).map { |p| [ p.work_order_id.to_s.rjust(6, "0"), p.amount, I18n.t("activerecord.enums.payment.payment_method.#{p.payment_method}"), p.cash_account&.name, p.comment, p.paid_at ] }
    CsvExport.generate(headers, rows)
  end

  def cash_operations
    attr = ->(name) { CashOperation.human_attribute_name(name) }
    rows = CashOperation.includes(:cash_account, :expense_category, :supplier).order(:occurred_at).map do |o|
      [ o.occurred_at, I18n.t("activerecord.enums.cash_operation.kind.#{o.kind}"), o.cash_account.name, o.amount, o.expense_category&.name, o.supplier&.name, o.comment ]
    end
    CsvExport.generate([ attr[:occurred_at], attr[:kind], CashAccount.model_name.human, attr[:amount], attr[:expense_category_id], attr[:supplier], attr[:comment] ], rows)
  end

  def t_total(key) = I18n.t("work_orders.totals.#{key}")
end
