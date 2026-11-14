require "test_helper"

class Admin::EmployeesControllerTest < ActionDispatch::IntegrationTest
  test "admin manages employees" do
    sign_in_as users(:admin)
    get admin_employees_path
    assert_select "td", text: "Иван Кузнецов"
    assert_difference(-> { Employee.count }) do
      post admin_employees_path, params: { employee: { name: "Пётр", position: "mechanic" } }
    end
  end

  test "non-admin is denied" do
    sign_in_as users(:advisor)
    get admin_employees_path
    assert_redirected_to root_path
  end
end
