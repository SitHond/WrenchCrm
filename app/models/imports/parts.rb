module Imports
  # Parts catalog and stock. Duplicates are found by SKU, then by name.
  class Parts < Definition
    field :name, required: true, aliases: [ "наименование", "название", "товар", "наименование товара", "name", "product" ]
    field :sku, aliases: [ "артикул", "номер товара", "код товара", "код", "каталожный номер", "sku", "part number" ]
    field :oem, aliases: [ "oem", "оригинальный номер", "oem номер" ]
    field :brand, aliases: [ "бренд", "производитель", "brand", "manufacturer" ]
    field :category, aliases: [ "категория", "группа", "category" ]
    field :unit, aliases: [ "ед изм", "единица", "ед", "unit" ]
    field :cost, aliases: [ "цена закупки", "закупочная цена", "себестоимость", "входная цена", "цена покупки", "cost" ], type: :decimal
    field :price, aliases: [ "цена", "цена продажи", "розничная цена", "price" ], type: :decimal
    field :quantity, aliases: [ "остаток", "количество", "кол во", "в наличии", "quantity", "stock" ], type: :decimal
    field :min_quantity, aliases: [ "минимальный остаток", "мин остаток", "min stock" ], type: :decimal
    field :location, aliases: [ "ячейка", "место хранения", "location", "bin" ]

    UNIT_ALIASES = { "шт" => "pcs", "штука" => "pcs", "pcs" => "pcs", "л" => "l", "литр" => "l", "l" => "l", "кг" => "kg", "kg" => "kg",
                     "м" => "m", "метр" => "m", "m" => "m", "компл" => "set", "комплект" => "set", "set" => "set" }.freeze

    def self.example_values
      { name: "Фильтр масляный", sku: "W712/95", brand: "MANN", category: "Фильтры", unit: "шт", cost: "450", price: "750", quantity: "10", min_quantity: "3", location: "B-3" }
    end

    def import_row(values)
      sku = values["sku"].presence
      part = (sku && Part.find_by(sku: sku)) || Part.where("LOWER(name) = ?", values["name"].to_s.strip.downcase).first
      existed = part.present?
      return Result.new(:skipped, part, []) if existed && !update?

      part ||= Part.new
      category = values["category"].presence && CatalogCategory.find_or_create_by!(kind: :part, name: values["category"].strip)
      unit = UNIT_ALIASES[values["unit"].to_s.downcase.delete(".").strip]
      assign(part, name: values["name"], sku: sku, oem: values["oem"], brand: values["brand"], category: category, unit: unit,
                   cost: decimal(values["cost"]), price: decimal(values["price"]), min_quantity: decimal(values["min_quantity"]), location: values["location"])
      quantity = decimal(values["quantity"])
      if existed
        result = save(part, true)
        part.set_quantity!(quantity, comment: I18n.t("imports.stock_comment")) if quantity && result.status == :updated
        result
      else
        part.quantity = quantity || 0
        save(part, false)
      end
    end
  end
end
