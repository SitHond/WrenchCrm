module Imports
  # Labor catalog. Duplicates are found by code, then by name.
  class Services < Definition
    field :name, required: true, aliases: [ "наименование", "название", "услуга", "работа", "наименование услуги", "name", "service" ]
    field :code, aliases: [ "код", "артикул", "code" ]
    field :category, aliases: [ "категория", "группа", "category" ]
    field :price, aliases: [ "цена", "стоимость", "price" ], type: :decimal
    field :norm_hours, aliases: [ "нормо часы", "норма времени", "нч", "hours" ], type: :decimal
    field :reminder_months, aliases: [ "напомнить через мес", "интервал мес" ], type: :integer
    field :reminder_km, aliases: [ "напомнить через км", "интервал км" ], type: :integer

    def self.example_values
      { name: "Замена масла в двигателе", code: "M01", category: "ТО", price: "1200", norm_hours: "0.5", reminder_months: "12", reminder_km: "10000" }
    end

    def import_row(values)
      code = values["code"].presence
      service = (code && Service.find_by(code: code)) || Service.where("LOWER(name) = ?", values["name"].to_s.strip.downcase).first
      existed = service.present?
      service ||= Service.new(price: 0)
      category = values["category"].presence && CatalogCategory.find_or_create_by!(kind: :service, name: values["category"].strip)
      assign(service, name: values["name"], code: code, category: category, price: decimal(values["price"]),
                      norm_hours: decimal(values["norm_hours"]), reminder_months: integer(values["reminder_months"]), reminder_km: integer(values["reminder_km"]))
      save(service, existed)
    end
  end
end
