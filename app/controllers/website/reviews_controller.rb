module Website
  class ReviewsController < ResourcesController
    private
      def resource_class = SiteReview
      def scope = SiteReview.order(:position, reviewed_on: :desc)
      def permitted = %i[ author text rating reviewed_on published position ]
      def defaults = { rating: 5, reviewed_on: Date.current }
  end
end
