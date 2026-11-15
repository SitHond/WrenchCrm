require "test_helper"

class ImportsTest < ActiveSupport::TestCase
  def import(kind, file, mode: "skip")
    content = file_fixture(file).binread
    DataImport.create!(kind: kind, filename: file, content: content, mode: mode).tap(&:run!)
  end

  test "clients with vehicles: auto mapping, duplicates by phone, blank rows and missing phones" do
    record = import("clients", "clients.csv")
    assert_equal({ "created" => 2, "skipped" => 1 }, record.counts.except("failed"))
    sidorov = Client.find_by!(email: "sidorov@example.com")
    assert_equal "Сидоров Пётр", sidorov.display_name
    vehicle = sidorov.vehicles.sole
    assert_equal [ "Kia", "Rio", "А111АА 77", 120_000 ], [ vehicle.make, vehicle.model, vehicle.plate_number, vehicle.mileage ]
    assert_equal "Постоянный клиент", sidorov.notes.sole.body
    assert_equal 1, clients(:petrov).vehicles.where(model: "Solaris").count, "existing client found by phone, vehicle not duplicated"
    assert Client.find_by(last_name: "Без телефона").phone.blank?
  end

  test "update mode overwrites with file values" do
    import("clients", "clients.csv")
    import("clients", "clients.csv", mode: "update")
    assert_equal 1, Client.where(email: "sidorov@example.com").count
  end

  test "parts from a Windows-1251 comma-separated file; missing name fails with an error report" do
    record = import("parts", "parts_cp1251.csv")
    assert_equal 2, record.counts["created"]
    assert_equal 1, record.counts["failed"]
    filter = Part.find_by!(sku: "AF-1")
    assert_equal [ "Фильтр воздушный", 300, 550, 4, "Фильтры" ], [ filter.name, filter.cost, filter.price, filter.quantity, filter.category.name ]
    assert_match "NO-NAME", record.errors_csv
  end

  test "parts update sets stock through a stock count" do
    import("parts", "parts_cp1251.csv")
    Part.find_by!(sku: "AF-1").update!(quantity: 1)
    import("parts", "parts_cp1251.csv", mode: "update")
    part = Part.find_by!(sku: "AF-1")
    assert_equal 4, part.quantity
    assert part.stock_movements.inventory.exists?
  end

  test "templates use field labels and are importable" do
    csv = Imports::Clients.template_csv
    assert csv.start_with?("﻿ФИО;")
    record = DataImport.create!(kind: "clients", filename: "t.csv", content: csv)
    record.run!
    assert_equal 1, record.counts["skipped"], "the example phone belongs to an existing client"
    assert_nil record.counts["failed"]
  end

  test "S+ reports rebuild history with original numbers and matching totals" do
    files = %w[splus_orders.csv splus_labor.csv splus_parts.csv].to_h { |f| [ f, file_fixture(f).binread ] }
    tables = Imports::Splus.detect(files)
    assert_equal %i[labor orders parts], tables.keys.sort
    result = Imports::Splus.new(tables).run!

    done = WorkOrder.find(900001)
    assert done.closed?
    assert_equal 12_000, done.total
    assert_equal 1000, done.labor_lines.find_by!(name: "Амортизаторы задние - с/у").price, "2 × 1000 after discount"
    assert_equal 4500, done.part_lines.sole.price
    assert_equal 4000, done.part_lines.sole.cost
    assert_equal I18n.t("imports.splus.undetailed"), done.labor_lines.order(:id).last.name
    assert_equal 12_000, done.payments.sole.amount
    assert_not done.payments.sole.cash_account.active?

    open_order = WorkOrder.find(900002)
    assert open_order.in_progress?
    assert_equal done.client, open_order.client, "same phone in another format"
    assert_equal done.vehicle, open_order.vehicle, "same plate"
    assert_equal "Lada", WorkOrder.find(900003).vehicle.make

    assert_equal WorkOrder.maximum(:id) + 1, WorkOrder.create!(vehicle: vehicles(:polo)).id, "numbering continues after the highest number"
    assert_equal 1, result["counts"]["sales"]
    assert_equal 0, Part.find_by!(sku: "AM-1").quantity, "history does not touch stock"
    assert_equal 2000, Service.find_by!(name: "Амортизаторы задние - с/у").price, "catalog keeps the price before discount"

    again = Imports::Splus.new(Imports::Splus.detect(files)).run!
    assert_equal 3, again["counts"]["orders_existing"]
    assert_equal 1, Sale.count
  end

  test "rejects files without rows" do
    record = DataImport.new(kind: "parts", filename: "empty.csv", content: "Наименование\n")
    assert_not record.valid?
  end
end
