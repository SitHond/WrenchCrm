require "test_helper"

class ClientTest < ActiveSupport::TestCase
  test "individual needs a last name, company needs a company name" do
    assert_not Client.new(phone: "1").valid?
    assert Client.new(phone: "1", last_name: "Иванов").valid?
    assert_not Client.new(kind: :company, phone: "1", last_name: "Иванов").valid?
  end

  test "validates INN length" do
    client = clients(:taxi)
    client.inn = "123"
    assert_not client.valid?
  end

  test "display name" do
    assert_equal "Петров Алексей", clients(:petrov).display_name
    assert_equal "ООО Такси", clients(:taxi).display_name
  end

  test "search by name, phone digits and vehicle plate" do
    assert_includes Client.search("петров"), clients(:petrov)
    assert_includes Client.search("8 916 555 12 34".delete_prefix("8 ")), clients(:petrov)
    assert_includes Client.search("а123вс"), clients(:petrov)
    assert_includes Client.search("Z94CT41"), clients(:petrov)
    assert_not_includes Client.search("петров"), clients(:taxi)
  end

  test "cannot delete a client with vehicles" do
    assert_not clients(:petrov).destroy
  end
end
