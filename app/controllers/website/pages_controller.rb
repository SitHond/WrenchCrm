module Website
  class PagesController < ResourcesController
    private
      def resource_class = SitePage
      def scope = SitePage.order(:position, :id)
      def permitted = %i[ title slug body published show_in_menu position ]
      def defaults = { position: SitePage.maximum(:position).to_i + 1 }
  end
end
