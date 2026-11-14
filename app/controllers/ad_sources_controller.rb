class AdSourcesController < ApplicationController
  require_permission :admin

  def create
    source = AdSource.new(params.expect(ad_source: [ :name ]))
    if source.save
      redirect_to edit_shop_settings_path(anchor: "ad-sources")
    else
      redirect_to edit_shop_settings_path(anchor: "ad-sources"), alert: source.errors.full_messages.to_sentence
    end
  end

  def update
    source = AdSource.find(params[:id])
    source.update!(active: !source.active)
    redirect_to edit_shop_settings_path(anchor: "ad-sources")
  end
end
