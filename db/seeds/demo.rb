return if Client.exists?

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
