# "1 234,50" -> "Одна тысяча двести тридцать четыре рубля 50 копеек", as Russian invoices and acts require.
module AmountInWords
  ONES = { masculine: %w[ноль один два три четыре пять шесть семь восемь девять],
           feminine: %w[ноль одна две три четыре пять шесть семь восемь девять] }.freeze
  TEENS = %w[десять одиннадцать двенадцать тринадцать четырнадцать пятнадцать шестнадцать семнадцать восемнадцать девятнадцать].freeze
  TENS = %w[_ _ двадцать тридцать сорок пятьдесят шестьдесят семьдесят восемьдесят девяносто].freeze
  HUNDREDS = %w[_ сто двести триста четыреста пятьсот шестьсот семьсот восемьсот девятьсот].freeze
  SCALES = [
    [ %w[тысяча тысячи тысяч], :feminine ],
    [ %w[миллион миллиона миллионов], :masculine ],
    [ %w[миллиард миллиарда миллиардов], :masculine ]
  ].freeze

  module_function

  def rubles(amount)
    amount = amount.to_d.round(2)
    rubles = amount.truncate.to_i
    kopecks = ((amount - rubles) * 100).round.to_i
    words = "#{number(rubles)} #{plural(rubles, %w[рубль рубля рублей])} #{format('%02d', kopecks)} #{plural(kopecks, %w[копейка копейки копеек])}"
    words[0].upcase + words[1..]
  end

  def number(value, gender = :masculine)
    return ONES[gender][0] if value.zero?

    groups = []
    value.digits(1000).each_with_index do |group, index|
      next if group.zero?

      if index.zero?
        groups.unshift(triplet(group, gender))
      else
        forms, scale_gender = SCALES.fetch(index - 1)
        groups.unshift("#{triplet(group, scale_gender)} #{plural(group, forms)}")
      end
    end
    groups.join(" ")
  end

  def triplet(value, gender)
    hundreds, rest = value.divmod(100)
    tens, ones = rest.divmod(10)
    words = []
    words << HUNDREDS[hundreds] if hundreds.positive?
    if tens == 1
      words << TEENS[ones]
    else
      words << TENS[tens] if tens > 1
      words << ONES[gender][ones] if ones.positive?
    end
    words.join(" ")
  end

  def plural(value, forms)
    mod100 = value % 100
    mod10 = value % 10
    return forms[2] if (11..14).cover?(mod100)
    return forms[0] if mod10 == 1
    return forms[1] if (2..4).cover?(mod10)

    forms[2]
  end
end
