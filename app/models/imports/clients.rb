module Imports
  # One row = a client and optionally their vehicle. Duplicates are found by phone, then email, then name.
  class Clients < Definition
    field :full_name, aliases: [ "фио", "клиент", "контрагент", "контакт", "имя клиента", "name", "full name", "contact name" ]
    field :last_name, aliases: [ "фамилия", "last name" ]
    field :first_name, aliases: [ "имя", "first name" ]
    field :middle_name, aliases: [ "отчество", "middle name" ]
    field :company_name, aliases: [ "компания", "организация", "название компании", "company" ]
    field :phone, aliases: [ "телефон", "мобильный телефон", "рабочий телефон", "номер телефона", "phone", "mobile" ]
    field :phone2, aliases: [ "телефон 2", "доп телефон", "другой телефон" ]
    field :email, aliases: [ "e mail", "email", "почта", "рабочий e mail", "электронная почта" ]
    field :inn, aliases: [ "инн", "tax id" ]
    field :address, aliases: [ "адрес", "address" ]
    field :discount_percent, aliases: [ "скидка", "скидка %", "discount" ], type: :decimal
    field :ad_source, aliases: [ "источник", "откуда узнал", "рекламный источник", "source" ]
    field :comment, aliases: [ "комментарий", "примечание", "заметка", "comment", "note" ]
    field :make, aliases: [ "марка", "make", "brand" ]
    field :model, aliases: [ "модель", "model" ]
    field :vehicle, aliases: [ "авто", "автомобиль", "машина", "vehicle", "car" ]
    field :year, aliases: [ "год", "год выпуска", "year" ], type: :integer
    field :plate_number, aliases: [ "госномер", "гос номер", "номер авто", "plate" ]
    field :vin, aliases: [ "vin", "vin код" ]
    field :mileage, aliases: [ "пробег", "mileage" ], type: :integer

    def self.example_values
      { full_name: "Петров Алексей Игоревич", phone: "+7 916 555-12-34", email: "petrov@example.com",
        make: "Hyundai", model: "Solaris", year: "2017", plate_number: "А123ВС777", vin: "Z94CT41DAJR123456", mileage: "98500" }
    end

    def import_row(values)
      client = find_existing(values)
      existed = client.present?
      client ||= Client.new
      if existed && !update?
        vehicle_result = import_vehicle(client, values)
        return Result.new(vehicle_result ? :updated : :skipped, client, [])
      end

      assign(client, client_attributes(values))
      client.kind = :company if values["company_name"].present? && values["full_name"].blank? && values["last_name"].blank?
      client.last_name = values["full_name"].presence || values["company_name"] if client.individual? && client.last_name.blank?
      result = save(client, existed)
      return result if result.status == :failed

      import_vehicle(client, values)
      client.notes.create!(body: values["comment"]) if values["comment"].present? && !existed
      result
    end

    private
      def find_existing(values)
        find_client_by_phone(values["phone"]) ||
          (values["email"].present? && Client.find_by(email: values["email"].strip.downcase)) ||
          (name = display_name(values)).presence && Client.where("TRIM(CONCAT_WS(' ', last_name, first_name, middle_name)) ILIKE ? OR company_name ILIKE ?", name, name).first
      end

      def display_name(values)
        values["full_name"].presence || [ values["last_name"], values["first_name"], values["middle_name"] ].compact_blank.join(" ").presence || values["company_name"]
      end

      def client_attributes(values)
        source = values["ad_source"].presence && AdSource.find_or_create_by!(name: values["ad_source"].strip)
        {
          last_name: values["last_name"].presence || values["full_name"].presence, first_name: values["first_name"], middle_name: values["middle_name"],
          company_name: values["company_name"], phone: values["phone"], phone2: values["phone2"], email: values["email"],
          inn: values["inn"]&.gsub(/\D/, "").presence, address: values["address"], discount_percent: decimal(values["discount_percent"]),
          ad_source: source
        }
      end

      def import_vehicle(client, values)
        make, model = values["make"].presence, values["model"].presence
        make, model = VehicleText.split(values["vehicle"]) if make.nil? && values["vehicle"].present?
        plate = PlateNumber.normalize(values["plate_number"]) || VehicleText.plate(values["vehicle"])
        vin = values["vin"].to_s.strip.upcase.presence
        return unless make || plate || vin

        vehicle = (vin && Vehicle.find_by(vin: vin)) || (plate && client.vehicles.find_by(plate_number: plate)) ||
                  (make && client.vehicles.find_by(make: VehicleCatalog.canonical_make(make), model: model || "—"))
        return if vehicle && !update?

        vehicle ||= client.vehicles.new
        assign(vehicle, make: make, model: model || vehicle.model || "—", year: integer(values["year"]), plate_number: plate, vin: vin, mileage: integer(values["mileage"]))
        vehicle.vin = nil if vehicle.vin && !vehicle.valid? && vehicle.errors.include?(:vin)
        vehicle.save
      end
  end
end
