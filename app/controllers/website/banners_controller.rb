module Website
  class BannersController < ResourcesController
    private
      def resource_class = SiteBanner
      def scope = SiteBanner.ordered.with_attached_image
      def permitted = %i[ title text button_text button_url position active starts_on ends_on image ]
      def defaults = { position: SiteBanner.maximum(:position).to_i + 1, button_text: I18n.t("site.booking.cta") }
  end
end
