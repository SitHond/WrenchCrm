# Decodes a VIN offline: the manufacturer and country come from the first three characters,
# and the model year from the 10th character.
class VinDecoder
  YEAR_CODES = "ABCDEFGHJKLMNPRSTVWXY123456789".chars.freeze

  attr_reader :vin

  def initialize(vin)
    @vin = vin.to_s.strip.upcase
  end

  def valid?
    vin.match?(/\A[A-HJ-NPR-Z0-9]{17}\z/)
  end

  def makes
    manufacturer&.fetch("makes", []) || []
  end

  def country
    manufacturer&.fetch("country", nil)
  end

  # The year code repeats every 30 years; pick the latest year that is not in the future.
  def year
    index = YEAR_CODES.index(vin[9])
    return unless valid? && index

    latest = Date.current.year + 1
    year = 1980 + index
    year += 30 while year + 30 <= latest
    year
  end

  def to_h
    { vin: vin, valid: valid?, makes: makes, country: country, year: year }
  end

  private
    def manufacturer
      VehicleCatalog.wmi(vin[0, 3]) if vin.length >= 3
    end
end
