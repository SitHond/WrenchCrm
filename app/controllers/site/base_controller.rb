module Site
  # Public pages: no sign-in, Russian by default, own layout.
  class BaseController < ActionController::Base
    layout "site"
    before_action :load_site
    around_action :russian
    helper_method :site, :shop

    rescue_from ActiveRecord::RecordNotFound do
      render "site/pages/not_found", status: :not_found
    end

    private
      def load_site
        @site = SiteSetting.current
        @shop = ShopSetting.current
        render "site/pages/disabled", status: :service_unavailable unless @site.enabled?
      end

      def site = @site
      def shop = @shop

      def russian(&action) = I18n.with_locale(:ru, &action)
  end
end
