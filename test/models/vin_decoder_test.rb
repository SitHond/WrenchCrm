require "test_helper"

class VinDecoderTest < ActiveSupport::TestCase
  test "manufacturer, country and year" do
    result = VinDecoder.new("x7lhsrh8n54123456").to_h
    assert result[:valid]
    assert_equal [ "Renault" ], result[:makes]
    assert_equal "Россия", result[:country]
    assert_equal 2005, result[:year]
  end

  test "shared plants return several makes" do
    assert_equal %w[Hyundai Kia], VinDecoder.new("Z94CT41DAJR123456").makes
  end

  test "year code picks the latest year that is not in the future" do
    travel_to Date.new(2026, 6, 1) do
      assert_equal 2018, VinDecoder.new("Z94CT41DAJR123456").year
      assert_equal 2026, VinDecoder.new("Z94CT41DATR123456").year
      assert_equal 2027, VinDecoder.new("Z94CT41DAVR123456").year, "next model year is allowed"
      assert_equal 1998, VinDecoder.new("Z94CT41DAWR123456").year
    end
  end

  test "invalid and unknown VINs" do
    assert_not VinDecoder.new("Z94CT41DAJR12345O").valid?
    assert_nil VinDecoder.new("SHORT").year
    assert_empty VinDecoder.new("AAA00000000000000").makes
  end
end
