# Public personal data processing policy (152-FZ art. 18.1): linked from the sign-in page and consent forms.
class PrivacyController < ApplicationController
  allow_unauthenticated_access
  skip_before_action :require_two_factor_setup

  def show
    @shop = ShopSetting.current
    render layout: "public"
  end
end
