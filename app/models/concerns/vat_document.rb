# VAT for a work order or a counter sale. The rate and whether prices include VAT are copied
# from shop settings when the document is created, so changing settings never rewrites history.
# Order-level discounts are spread over the lines because documents show VAT per line.
module VatDocument
  extend ActiveSupport::Concern

  RATES = [ 5, 7, 10, 22 ].freeze
  UNIT_CODES = { "pcs" => [ "796", "шт" ], "l" => [ "112", "л" ], "kg" => [ "166", "кг" ], "m" => [ "006", "м" ],
                 "set" => [ "839", "компл" ], "service" => [ "876", "усл. ед" ] }.freeze

  Line = Struct.new(:name, :kind, :unit, :quantity, :amount, :vat, keyword_init: true) do
    # amount: what the customer pays for the line after discounts (with VAT when VAT applies)
    def amount_without_vat = amount - vat
    def price_without_vat = quantity.zero? ? amount_without_vat : (amount_without_vat / quantity).round(2)
    def unit_code = UNIT_CODES.fetch(unit, UNIT_CODES["pcs"])
  end

  included do
    before_create :copy_vat_settings, unless: -> { Current.importing }
  end

  def vat? = vat_rate.to_i.positive?

  # Lines before VAT is added on top: [kind, name, unit, quantity, amount after discounts].
  def priced_lines
    raise NotImplementedError
  end

  def vat_lines
    @vat_lines ||= priced_lines.map do |kind, name, unit, quantity, amount|
      amount = amount.round(2)
      vat = if !vat? then 0
      elsif vat_included then (amount * vat_rate / (100 + vat_rate)).round(2)
      else (amount * vat_rate / 100).round(2)
      end
      Line.new(name: name, kind: kind, unit: unit, quantity: quantity, amount: vat_included ? amount : amount + vat, vat: vat)
    end
  end

  def vat_amount = vat? ? vat_lines.sum(&:vat) : 0

  def vat_label
    return I18n.t("vat.none") unless vat?

    I18n.t(vat_included ? "vat.included" : "vat.on_top", rate: vat_rate)
  end

  def reset_vat_lines!
    @vat_lines = nil
  end

  private
    def copy_vat_settings
      setting = ShopSetting.current
      self.vat_rate = setting.vat_rate
      self.vat_included = setting.vat_included
    end

    # Spreads a discount over amounts so the parts add up exactly.
    def spread(amounts, discount)
      return amounts if discount.zero? || amounts.sum.zero?

      total = amounts.sum
      shares = amounts.map { |a| (discount * a / total).round(2) }
      shares[-1] += discount - shares.sum
      amounts.zip(shares).map { |a, s| a - s }
    end
end
