module Imports
  # Suppliers. Duplicates are found by INN, then by name.
  class Suppliers < Definition
    field :name, required: true, aliases: [ "наименование", "название", "поставщик", "контрагент", "name", "supplier" ]
    field :inn, aliases: [ "инн", "tax id" ]
    field :phone, aliases: [ "телефон", "phone" ]
    field :email, aliases: [ "e mail", "email", "почта" ]
    field :contact_person, aliases: [ "контактное лицо", "контакт", "contact" ]
    field :comment, aliases: [ "комментарий", "примечание", "comment" ]

    def self.example_values
      { name: "ООО «АвтоДеталь»", inn: "7712345678", phone: "+7 495 111-22-33", email: "zakaz@example.com", contact_person: "Сергей" }
    end

    def import_row(values)
      inn = values["inn"]&.gsub(/\D/, "").presence
      supplier = (inn && Supplier.find_by(inn: inn)) || Supplier.where("LOWER(name) = ?", values["name"].to_s.strip.downcase).first
      existed = supplier.present?
      supplier ||= Supplier.new
      assign(supplier, name: values["name"], inn: inn, phone: values["phone"], email: values["email"],
                       contact_person: values["contact_person"], comment: values["comment"])
      save(supplier, existed)
    end
  end
end
