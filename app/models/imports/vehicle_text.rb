module Imports
  # "Ford Fiesta 5 (а010мк147)" -> make "Ford", model "Fiesta 5", plate "А010МК 147".
  module VehicleText
    MAKE_ALIASES = { "vaz" => "Lada", "ваз" => "Lada", "лада" => "Lada", "mercedes" => "Mercedes-Benz", "мерседес" => "Mercedes-Benz",
                     "vw" => "Volkswagen", "фольксваген" => "Volkswagen", "форд" => "Ford", "рено" => "Renault", "шкода" => "Skoda",
                     "киа" => "Kia", "хендай" => "Hyundai", "хендэ" => "Hyundai", "тойота" => "Toyota", "ниссан" => "Nissan" }.freeze

    module_function

    def plate(text)
      inner = text.to_s[/\(([^)]+)\)\s*\z/, 1]
      PlateNumber.normalize(inner) if inner
    end

    def split(text)
      name = text.to_s.sub(/\([^)]*\)\s*\z/, "").strip
      return [ nil, nil ] if name.empty?

      make, model = name.split(/\s+/, 2)
      [ MAKE_ALIASES.fetch(make.downcase) { canonical_make(make) }, model.presence ]
    end

    def canonical_make(make)
      canonical = VehicleCatalog.canonical_make(make)
      canonical == make && make == make.downcase ? make.capitalize : canonical
    end
  end
end
