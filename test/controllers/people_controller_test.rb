require "test_helper"

class PeopleControllerTest < ActionDispatch::IntegrationTest
  test "viewer can list and view people" do
    sign_in_as users(:viewer)
    get people_path
    assert_response :success
    assert_select "td", text: /Иванов Сергей/

    get person_path(people(:sergey))
    assert_response :success
  end

  test "editor creates a person in a family" do
    sign_in_as users(:editor)
    assert_difference -> { Person.count } do
      post people_path, params: { person: { first_name: "Анна", last_name: "Иванова", family_id: families(:ivanovs).id,
                                            family_role: "spouse", classification: "member", gender: "female" } }
    end
    person = Person.last
    assert_redirected_to person_path(person)
    assert_equal users(:editor), person.created_by
    assert person.spouse?
  end

  test "invalid person re-renders the form" do
    sign_in_as users(:editor)
    post people_path, params: { person: { first_name: "", last_name: "" } }
    assert_response :unprocessable_entity
  end

  test "editor updates a person" do
    sign_in_as users(:editor)
    patch person_path(people(:guest)), params: { person: { classification: "regular_attender" } }
    assert people(:guest).reload.regular_attender?
  end

  test "viewer cannot create" do
    sign_in_as users(:viewer)
    assert_no_difference -> { Person.count } do
      post people_path, params: { person: { first_name: "X", last_name: "Y" } }
    end
    assert_redirected_to root_path
  end

  test "editor cannot delete, admin can" do
    sign_in_as users(:editor)
    assert_no_difference(-> { Person.count }) { delete person_path(people(:guest)) }

    sign_in_as users(:admin)
    assert_difference(-> { Person.count }, -1) { delete person_path(people(:guest)) }
  end

  test "filters by classification" do
    sign_in_as users(:viewer)
    get people_path(classification: "guest")
    assert_select "td", text: /Соколов/
    assert_select "td", text: /Иванов Сергей/, count: 0
  end
end
