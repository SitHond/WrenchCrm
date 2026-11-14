class LoyaltyTiersController < ApplicationController
  require_permission :admin

  def create
    tier = LoyaltyTier.new(params.expect(loyalty_tier: [ :threshold, :labor_percent, :parts_percent ]))
    if tier.save
      redirect_to edit_shop_settings_path(anchor: "loyalty")
    else
      redirect_to edit_shop_settings_path(anchor: "loyalty"), alert: tier.errors.full_messages.to_sentence
    end
  end

  def destroy
    LoyaltyTier.find(params[:id]).destroy
    redirect_to edit_shop_settings_path(anchor: "loyalty"), status: :see_other
  end
end
