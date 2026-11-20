require "test_helper"

class WarrantyControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:advisor) }

  test "warranty shows on documents, the vehicle and claims link both ways" do
    services(:oil_change).update!(warranty_months: 6)
    order = WorkOrder.create!(vehicle: vehicles(:solaris))
    order.labor_lines.create!(service: services(:oil_change))
    order.change_status!(:in_progress)
    order.change_status!(:ready)
    order.change_status!(:closed)

    get print_work_order_path(order, doc: "act")
    assert_match "6 мес.", response.body
    get vehicle_path(vehicles(:solaris))
    assert_match "Действующие гарантии", response.body

    get new_work_order_path(vehicle_id: vehicles(:solaris).id, warranty_of_id: order.id)
    assert_select "select#work_order_warranty_of_id option[selected]"
    post work_orders_path, params: { work_order: { vehicle_id: vehicles(:solaris).id, warranty_of_id: order.id, complaint: "Течь масла" } }
    claim = WorkOrder.last
    assert_equal order, claim.warranty_of
    get work_order_path(order)
    assert_match "гарантия: № #{claim.number}", response.body
  end
end
