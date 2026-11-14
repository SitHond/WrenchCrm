require "test_helper"

class PlateNumberTest < ActiveSupport::TestCase
  test "converts Latin look-alikes and formats Russian plates" do
    assert_equal "А123ВС 77", PlateNumber.normalize("a123bc77")
    assert_equal "А123ВС 777", PlateNumber.normalize(" а123вс  777 ")
    assert_equal "А123ВС", PlateNumber.normalize("a123bc")
  end

  test "keeps foreign plates as they are" do
    assert_equal "ABC-1234", PlateNumber.normalize("abc-1234")
  end

  test "blank stays blank" do
    assert_nil PlateNumber.normalize("  ")
  end
end
