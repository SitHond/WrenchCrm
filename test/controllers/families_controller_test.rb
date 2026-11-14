require "test_helper"

class FamiliesControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  test "index and show" do
    get families_path
    assert_select "a", text: "Ивановы"
    get family_path(families(:ivanovs))
    assert_select "a", text: "Сергей Иванов"
  end

  test "create" do
    assert_difference(-> { Family.count }) do
      post families_path, params: { family: { name: "Смирновы", city: "Казань" } }
    end
    assert_redirected_to family_path(Family.last)
  end

  test "destroy keeps people" do
    assert_no_difference(-> { Person.count }) { delete family_path(families(:ivanovs)) }
    assert_nil people(:sergey).reload.family
  end
end
