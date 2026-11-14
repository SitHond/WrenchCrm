class CatalogCategoriesController < ApplicationController
  require_permission :manage_catalog

  def create
    category = CatalogCategory.new(params.expect(catalog_category: [ :name, :kind ]))
    if category.save
      redirect_back fallback_location: parts_path, notice: t("flash.created", model: CatalogCategory.model_name.human)
    else
      redirect_back fallback_location: parts_path, alert: category.errors.full_messages.to_sentence
    end
  end

  def destroy
    CatalogCategory.find(params[:id]).destroy
    redirect_back fallback_location: parts_path, status: :see_other
  end
end
