unless Client.exists?
  ActiveRecord::Base.transaction do
    ivan = Employee.create!(name: "Иван Кузнецов", position: :mechanic, phone: "+7 900 100-00-01")
    oleg = Employee.create!(name: "Олег Смирнов", position: :mechanic, phone: "+7 900 100-00-02")
    Employee.create!(name: "Марина Орлова", position: :service_advisor, phone: "+7 900 100-00-03")

    services = {
      diag: Service.create!(code: "D01", name: "Компьютерная диагностика", norm_hours: 0.5, price: 1500),
      oil: Service.create!(code: "M01", name: "Замена масла в двигателе", norm_hours: 0.5, price: 1200),
      pads: Service.create!(code: "B01", name: "Замена передних тормозных колодок", norm_hours: 1, price: 2000),
      tires: Service.create!(code: "T01", name: "Шиномонтаж, комплект 4 колеса", norm_hours: 1, price: 3200),
      align: Service.create!(code: "S01", name: "Развал-схождение", norm_hours: 1, price: 2500)
    }

    parts = {
      oil: Part.create!(sku: "SH-5W30-4", name: "Масло моторное 5W-30, 4 л", brand: "Shell", unit: "pcs", cost: 2900, price: 3800, quantity: 12, min_quantity: 4),
      filter: Part.create!(sku: "MANN-W712", name: "Фильтр масляный", brand: "MANN", unit: "pcs", cost: 450, price: 750, quantity: 3, min_quantity: 5),
      pads: Part.create!(sku: "TRW-GDB1550", name: "Колодки тормозные передние", brand: "TRW", unit: "set", cost: 2400, price: 3600, quantity: 4, min_quantity: 2),
      fluid: Part.create!(sku: "DOT4-1", name: "Тормозная жидкость DOT 4", brand: "Bosch", unit: "l", cost: 400, price: 650, quantity: 6, min_quantity: 2)
    }

    petrov = Client.create!(last_name: "Петров", first_name: "Алексей", middle_name: "Игоревич", phone: "+7 916 555-12-34", email: "petrov@example.com")
    solaris = petrov.vehicles.create!(make: "Hyundai", model: "Solaris", year: 2017, plate_number: "А123ВС 777", vin: "Z94CT41DAJR123456", color: "Белый", mileage: 98_500)

    ivanova = Client.create!(last_name: "Иванова", first_name: "Елена", phone: "+7 926 222-33-44", discount_percent: 5)
    rio = ivanova.vehicles.create!(make: "Kia", model: "Rio", year: 2020, plate_number: "М456ОР 799", color: "Синий", mileage: 41_200)

    taxi = Client.create!(kind: :company, company_name: "ООО «Быстрое такси»", inn: "7701234567", phone: "+7 495 777-00-00", discount_percent: 10)
    polo = taxi.vehicles.create!(make: "Volkswagen", model: "Polo", year: 2019, plate_number: "Т789ХК 750", mileage: 210_000)
    taxi.vehicles.create!(make: "Skoda", model: "Rapid", year: 2021, plate_number: "Т790ХК 750", mileage: 156_000)

    done = WorkOrder.create!(vehicle: solaris, mechanic: ivan, mileage: 95_000, complaint: "Плановое ТО",
                             created_at: 3.weeks.ago, recommendations: "Через 5 000 км заменить передние колодки.")
    done.labor_lines.create!(service: services[:oil], employee: ivan)
    done.part_lines.create!(part: parts[:oil])
    done.part_lines.create!(part: parts[:filter])
    done.change_status!(:in_progress)
    done.change_status!(:ready)
    done.payments.create!(amount: done.reload.total, payment_method: :card)
    done.change_status!(:closed)

    brakes = WorkOrder.create!(vehicle: solaris, mechanic: oleg, mileage: 98_500, complaint: "Скрип при торможении", promised_at: Date.current.noon)
    brakes.labor_lines.create!(service: services[:diag], employee: oleg)
    brakes.labor_lines.create!(service: services[:pads], employee: oleg)
    brakes.part_lines.create!(part: parts[:pads])
    brakes.part_lines.create!(part: parts[:fluid], quantity: 1)
    brakes.change_status!(:in_progress)

    tires = WorkOrder.create!(vehicle: rio, mechanic: ivan, complaint: "Сезонная смена шин, проверить развал")
    tires.labor_lines.create!(service: services[:tires], employee: ivan)
    tires.labor_lines.create!(service: services[:align], employee: ivan)
    tires.change_status!(:in_progress)
    tires.change_status!(:ready)

    fleet = WorkOrder.create!(vehicle: polo, complaint: "Горит Check Engine, плавают обороты на холостом ходу")
    fleet.labor_lines.create!(service: services[:diag])
    fleet.change_status!(:waiting_parts)
    fleet.notes.create!(body: "Заказан датчик положения дроссельной заслонки, поставка в четверг.")
  end
  puts "Loaded demo data"
end

unless Bay.exists?
  ActiveRecord::Base.transaction do
    lifts = [ "Подъёмник 1", "Подъёмник 2", "Шиномонтаж" ].each_with_index.map { |name, i| Bay.create!(name: name, position: i + 1) }
    mechanics = Employee.mechanic.active.to_a
    vehicles = Vehicle.limit(4).to_a
    today = Date.current.in_time_zone

    [
      [ 0, 10, 60, "Замена масла и фильтров" ],
      [ 0, 14, 120, "Диагностика подвески, стук спереди" ],
      [ 1, 11, 90, "Замена тормозных колодок" ],
      [ 2, 12, 60, "Сезонная смена шин" ],
      [ 2, 16, 30, "Подкачка, проверка давления" ]
    ].each_with_index do |(bay, hour, minutes, description), i|
      next unless vehicles.any?

      Appointment.create!(vehicle: vehicles[i % vehicles.size], bay: lifts[bay], mechanic: mechanics[i % [ mechanics.size, 1 ].max],
                          starts_at: today.change(hour: hour), duration_minutes: minutes, description: description,
                          status: i.even? ? :confirmed : :scheduled)
    end
    if vehicles.any?
      Appointment.create!(vehicle: vehicles.first, bay: lifts.first, starts_at: (today + 1.day).change(hour: 9, min: 30),
                          duration_minutes: 180, description: "Замена ремня ГРМ")
    end
  end
  puts "Loaded demo appointments"
end

unless Supplier.exists?
  ActiveRecord::Base.transaction do
    cash = CashAccount.default_for(:cash)
    bank = CashAccount.default_for(:card)
    %w[Аренда Коммунальные\ услуги Инструмент Реклама Хозтовары].each { |name| ExpenseCategory.find_or_create_by!(name: name, kind: :expense) }
    ExpenseCategory.find_or_create_by!(name: "Сдача металлолома", kind: :income)

    Employee.mechanic.each { |employee| employee.update!(labor_percent: 40, monthly_salary: 20_000) }
    Employee.service_advisor.each { |employee| employee.update!(order_percent: 5, monthly_salary: 35_000) }

    parts_supplier = Supplier.create!(name: "ООО «АвтоДеталь»", inn: "7712345678", phone: "+7 495 111-22-33", contact_person: "Сергей")
    Supplier.create!(name: "ИП Маслов (масла и жидкости)", phone: "+7 916 000-11-22")

    oil = Part.find_by(sku: "SH-5W30-4")
    filter = Part.find_by(sku: "MANN-W712")
    if oil && filter
      oil.update!(location: "A-1", oem: "550046306")
      filter.update!(location: "B-3", oem: "26300-35503")
      receipt = parts_supplier.purchase_receipts.create!(number: "АД-1024", received_on: 3.days.ago.to_date)
      receipt.lines.create!(part: oil, quantity: 6, cost: 2950)
      receipt.lines.create!(part: filter, quantity: 10, cost: 430)
      receipt.post!
      CashOperation.create!(kind: :supplier_payment, cash_account: bank, supplier: parts_supplier, amount: -15_000,
                            occurred_at: 2.days.ago, comment: "Частичная оплата АД-1024")

      Sale.create!(payment_method: :cash, lines_attributes: [ { part_id: oil.id, quantity: 1 } ], comment: "Продажа с прилавка")
    end

    CashOperation.create!(kind: :expense, cash_account: bank, amount: -45_000, occurred_at: Date.current.beginning_of_month.in_time_zone.change(hour: 10),
                          expense_category: ExpenseCategory.find_by(name: "Аренда"), comment: "Аренда бокса")
    CashOperation.create!(kind: :expense, cash_account: cash, amount: -1_200, expense_category: ExpenseCategory.find_by(name: "Хозтовары"), comment: "Перчатки, ветошь")
  end
  puts "Loaded demo finance and stock"
end

unless ServiceReminder.exists?
  oil = Service.find_by(code: "M01")
  oil&.update!(reminder_months: 12, reminder_km: 10_000)
  Service.find_by(code: "B01")&.update!(reminder_km: 30_000)
  solaris = Vehicle.find_by(plate_number: "А123ВС 777")
  rio = Vehicle.find_by(plate_number: "М456ОР 799")
  solaris&.service_reminders&.create!(service: oil, title: oil&.name || "Замена масла", due_on: Date.current + 5, due_mileage: (solaris.mileage || 0) + 500)
  rio&.service_reminders&.create!(title: "Замена тормозной жидкости", due_on: Date.current - 3, comment: "Рекомендовано при прошлом визите")
  puts "Loaded demo reminders"
end
