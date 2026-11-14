# Suggestions for the vehicle form: the bundled catalog merged with values already used in the shop.
module VehicleCatalog
  module_function

  def data
    @data ||= YAML.load_file(Rails.root.join("config/vehicle_catalog.yml")).freeze
  end

  def canonical_make(name)
    return name if name.blank?

    stripped = name.strip
    data["makes"].keys.find { |make| make.casecmp?(stripped) } ||
      Vehicle.where("LOWER(make) = ?", stripped.downcase).pick(:make) ||
      stripped
  end

  # { "Renault" => ["Duster", "Logan", ...], ... }
  def models_by_make
    models = data["makes"].transform_values { |list| list.map(&:to_s) }
    Vehicle.distinct.pluck(:make, :model).each do |make, model|
      key = models.keys.find { |known| known.casecmp?(make) } || make
      list = (models[key] ||= [])
      list << model unless list.any? { |known| known.casecmp?(model) }
    end
    models.sort_by { |make, _| make.downcase }.to_h
  end

  def colors
    (data["colors"] + Vehicle.where.not(color: [ nil, "" ]).distinct.pluck(:color)).uniq { |c| c.downcase }
  end

  def engines
    Vehicle.where.not(engine: [ nil, "" ]).distinct.order(:engine).pluck(:engine)
  end

  def wmi(code)
    data["wmi"][code]
  end
end
