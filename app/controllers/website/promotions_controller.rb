module Website
  class PromotionsController < ResourcesController
    private
      def resource_class = SitePromotion
      def scope = SitePromotion.order(created_at: :desc).with_attached_image
      def permitted = %i[ title text active starts_on ends_on image ]
  end
end
