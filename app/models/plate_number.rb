# Russian plates use the Cyrillic letters that look like Latin ones (А В Е К М Н О Р С Т У Х).
# Latin input is converted so "a123bc77" and "А123ВС 77" find the same car.
module PlateNumber
  LATIN = "ABEKMHOPCTYX".freeze
  CYRILLIC = "АВЕКМНОРСТУХ".freeze
  RUSSIAN = /\A([#{CYRILLIC}])\s*(\d{3})\s*([#{CYRILLIC}]{2})\s*(\d{2,3})?\z/

  module_function

  def normalize(value)
    plate = value.to_s.strip.upcase.gsub(/\s+/, " ")
    return if plate.empty?

    cyrillic = plate.tr(LATIN, CYRILLIC)
    match = RUSSIAN.match(cyrillic)
    return plate unless match || cyrillic.match?(/\A[#{CYRILLIC}0-9 ]+\z/)
    return cyrillic unless match

    [ "#{match[1]}#{match[2]}#{match[3]}", match[4] ].compact.join(" ")
  end
end
