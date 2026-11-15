module Imports
  # Rebuilds history from three S+ (splus.ru) report exports:
  #   "Заказ-наряды" (orders), "Количество продаж" by goods (parts lines) and by services (labor lines).
  # Order numbers are kept, so new orders continue after the last imported one.
  class Splus
    STATUSES = { "Выполнен" => :closed, "Заявка" => :accepted, "В работе" => :in_progress, "Ожидает запчасти" => :waiting_parts,
                 "Отменен" => :cancelled, "Отменён" => :cancelled, "Черновик" => :estimate }.freeze
    ACCOUNT_NAME = "Импорт из S+".freeze

    Report = Struct.new(:orders, :parts, :labor, :counts, :warnings)

    # files: { filename => content }; each report is recognised by its header.
    def self.detect(files)
      files.each_with_object({}) do |(name, content), found|
        table = TableReader.read(content, name)
        headers = table.headers.map { |h| TableReader.normalize_header(h) }
        key = if headers.include?("номер товара") then :parts
        elsif headers.include?("наименование услуги") then :labor
        elsif headers.include?("контрагент") && headers.include?("статус") && headers.include?("сумма") then :orders
        end
        found[key] = table if key
      end
    end

    def initialize(tables)
      @tables = tables
      @counts = Hash.new(0)
      @warnings = []
      @clients = {}
    end

    def run!
      raise ArgumentError, I18n.t("imports.splus.orders_missing") unless @tables[:orders]

      Current.set(importing: true) do
        ApplicationRecord.transaction do
          @account = CashAccount.find_or_create_by!(name: ACCOUNT_NAME) { |a| a.kind = :cash; a.active = false; a.position = 99 }
          labor = group_lines(:labor, "номер заказ наряда")
          parts = group_parts
          rows(:orders).each { |row| import_order(row, labor.fetch(row["№"], []), parts.fetch(row["№"], [])) }
          import_counter_sales(parts.fetch(:sales, {}))
          WorkOrder.reset_number_sequence!
        end
      end
      { "counts" => @counts, "warnings" => @warnings.first(200) }
    end

    private
      def rows(key)
        table = @tables[key]
        return [] unless table

        table.rows.map { |row| table.headers.zip(row).to_h }
      end

      def value(row, header)
        row.find { |k, _| TableReader.normalize_header(k) == header }&.last.to_s.strip
      end

      def group_lines(key, number_header)
        rows(key).group_by { |row| value(row, number_header) }
      end

      def group_parts
        rows(:parts).each_with_object({ sales: Hash.new { |h, k| h[k] = [] } }) do |row, groups|
          doc = value(row, "документ продажи")
          if (number = doc[/Заказ-наряд №(\d+)/, 1])
            (groups[number] ||= []) << row
          elsif (number = doc[/Продажа №(\d+)/, 1])
            groups[:sales][number] << row
          end
        end
      end

      def time(text)
        match = text.to_s.match(/(\d{2})\.(\d{2})\.(\d{4})(?:\D+(\d{2}):(\d{2}))?/)
        Time.zone.local(match[3].to_i, match[2].to_i, match[1].to_i, match[4].to_i, match[5].to_i) if match
      end

      def money(text)
        text.to_s.tr(",", ".").gsub(/[^\d.\-]/, "").to_d
      end

      def import_order(row, labor_rows, part_rows)
        number = row["№"].to_i
        if WorkOrder.exists?(number)
          @counts["orders_existing"] += 1
          return
        end

        client = client_for(row["Контрагент"], row["Телефон"])
        vehicle = vehicle_for(client, row["Авто"])
        created = time(row["Дата создания"]) || Time.current
        finished = time(row["Дата окончания"]) || created
        status = STATUSES.fetch(row["Статус"]) { @warnings << "№#{number}: #{row["Статус"]}"; :accepted }
        order = WorkOrder.create!(id: number, client: client, vehicle: vehicle, status: status, created_at: created, updated_at: finished,
                                  completed_at: (finished if status == :closed), closed_at: (finished if status == :closed),
                                  labor_discount_percent: 0, parts_discount_percent: 0)
        labor_rows.each { |line| add_labor(order, line) }
        part_rows.each { |line| add_part(order, line) }
        reconcile(order, money(row["Сумма"]))
        if order.closed? && order.total.positive?
          order.payments.create!(amount: order.total, payment_method: :cash, paid_at: finished, cash_account: @account, comment: ACCOUNT_NAME)
        end
        @counts["orders"] += 1
      end

      def client_for(name, phone)
        name = name.to_s.strip.presence || I18n.t("imports.splus.no_name")
        digits = phone.to_s.gsub(/\D/, "").last(10)
        key = digits.length == 10 ? digits : "name:#{name.downcase}"
        @clients[key] ||= begin
          existing = (digits.length == 10 && Client.where("RIGHT(regexp_replace(phone, '\\D', '', 'g'), 10) = ?", digits).first) ||
                     (digits.length < 10 && Client.where(phone: [ nil, "" ]).where("LOWER(last_name) = ?", name.downcase).first)
          existing || Client.create!(last_name: name, phone: phone.to_s.strip.presence).tap { @counts["clients"] += 1 }
        end
      end

      def vehicle_for(client, text)
        make, model = VehicleText.split(text)
        plate = VehicleText.plate(text)
        make ||= I18n.t("imports.splus.unknown_vehicle")
        model ||= "—"
        (plate && client.vehicles.find_by(plate_number: plate)) ||
          client.vehicles.find_by(make: make, model: model, plate_number: plate) ||
          client.vehicles.create!(make: make, model: model, plate_number: plate).tap { @counts["vehicles"] += 1 }
      end

      # quantity, unit price: exact cents when the line total divides evenly, otherwise one line of the total.
      def quantity_and_price(quantity, total)
        quantity = quantity.positive? ? quantity : 1
        unit = (total / quantity).round(2)
        unit * quantity == total ? [ quantity, unit ] : [ 1, total ]
      end

      def add_labor(order, row)
        name = value(row, "наименование услуги")
        total = money(value(row, "стоимость"))
        discount = money(value(row, "скидка"))
        quantity, price = quantity_and_price(money(value(row, "количество")), total)
        service = Service.where("LOWER(name) = ?", name.downcase).first ||
                  Service.create!(name: name, price: base_price(price, discount)).tap { @counts["services"] += 1 }
        order.labor_lines.create!(service: (service if price.positive?), name: name, quantity: quantity, price: price)
        @counts["labor_lines"] += 1
      end

      def add_part(order, row)
        part = part_for(row)
        total = money(value(row, "цена продажи"))
        quantity, price = quantity_and_price(money(value(row, "количество")), total)
        cost = (money(value(row, "цена покупки")) / quantity).round(2)
        line = order.part_lines.create!(part: (part if price.positive?), name: part.name, quantity: quantity, price: price)
        line.update_column(:cost, cost)
        @counts["part_lines"] += 1
      end

      def part_for(row)
        sku = value(row, "номер товара").presence
        name = value(row, "наименование")
        part = (sku && Part.find_by(sku: sku)) || Part.where("LOWER(name) = ?", name.downcase).first
        return part if part

        quantity = money(value(row, "количество"))
        quantity = 1 if quantity <= 0
        category = value(row, "категория").presence
        Part.create!(name: name, sku: sku, quantity: 0,
                     category: category && CatalogCategory.find_or_create_by!(kind: :part, name: category),
                     cost: (money(value(row, "цена покупки")) / quantity).round(2),
                     price: base_price((money(value(row, "цена продажи")) / quantity).round(2), money(value(row, "скидка")))).tap { @counts["parts"] += 1 }
      end

      def base_price(price, discount)
        discount.positive? && discount < 100 ? (price / (1 - discount / 100)).round(2) : price
      end

      # Make the order total match S+: a visible line for what the reports did not detail, or a discount when lines exceed it.
      def reconcile(order, expected)
        order.reload
        difference = expected - order.total
        if difference > 0.009
          order.labor_lines.create!(name: I18n.t("imports.splus.undetailed"), quantity: 1, price: difference)
          @counts["undetailed_lines"] += 1
        elsif difference < -0.009
          order.update_columns(discount_amount: -difference)
          @counts["discounted_orders"] += 1
        end
      end

      def import_counter_sales(sales)
        sales.each do |number, lines|
          first = lines.first
          client = value(first, "контрагент").presence && client_for(value(first, "контрагент"), nil)
          sold_at = time(value(first, "дата")) || Time.current
          next if Sale.exists?(comment: "S+ #{number}")

          sale = Sale.create!(client: client, payment_method: :cash, cash_account: @account, sold_at: sold_at, discount_percent: 0,
                              comment: "S+ #{number}", lines_attributes: lines.map { |row|
                                total = money(value(row, "цена продажи"))
                                quantity, price = quantity_and_price(money(value(row, "количество")), total)
                                { part_id: part_for(row).id, name: value(row, "наименование"), quantity: quantity, price: price }
                              })
          sale.update_columns(created_at: sold_at)
          @counts["sales"] += 1
        end
      end
  end
end
