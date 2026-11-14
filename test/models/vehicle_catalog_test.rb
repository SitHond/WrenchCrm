require "test_helper"

class VehicleCatalogTest < ActiveSupport::TestCase
  test "canonical make from catalog or existing vehicles" do
    assert_equal "Renault", VehicleCatalog.canonical_make(" renault ")
    Vehicle.create!(client: clients(:petrov), make: "Moskvich", model: "3")
    assert_equal "Moskvich", VehicleCatalog.canonical_make("MOSKVICH")
  end

  test "models include ones entered in the shop" do
    Vehicle.create!(client: clients(:petrov), make: "renault", model: "Dokker")
    assert_includes VehicleCatalog.models_by_make["Renault"], "Dokker"
    assert_includes VehicleCatalog.models_by_make["Renault"], "Duster"
  end
end
