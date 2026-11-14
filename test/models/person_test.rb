require "test_helper"

class PersonTest < ActiveSupport::TestCase
  test "age counts only after the birthday" do
    person = people(:sergey)
    assert_equal 44, person.age(on: Date.new(2025, 3, 11))
    assert_equal 45, person.age(on: Date.new(2025, 3, 12))
  end

  test "age is unknown without birth year" do
    person = Person.new(first_name: "A", last_name: "B", birth_day: 1, birth_month: 1)
    assert_nil person.age
    assert person.valid?
  end

  test "rejects impossible birth date" do
    person = Person.new(first_name: "A", last_name: "B", birth_day: 31, birth_month: 2)
    assert_not person.valid?
    assert person.errors.added?(:birth_day, :invalid)
  end

  test "search matches full name in either order and email" do
    assert_includes Person.search("Сергей Иванов"), people(:sergey)
    assert_includes Person.search("иванов серг"), people(:sergey)
    assert_includes Person.search("sergey@"), people(:sergey)
    assert_not_includes Person.search("Сергей"), people(:guest)
  end

  test "falls back to family address" do
    assert_equal [ "ул. Ленина, 10", "Москва" ], people(:sergey).effective_address_lines
  end

  test "destroying a person removes notes and memberships" do
    person = people(:guest)
    assert_difference -> { Note.count }, -2 do
      person.destroy
    end
    assert_difference -> { GroupMembership.count }, -1 do
      people(:sergey).destroy
    end
  end
end
