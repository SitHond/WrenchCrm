module Site
  class HomeController < BaseController
    def show
      @banners = SiteBanner.current.ordered.with_attached_image
      @promotions = SitePromotion.current.ordered.with_attached_image.limit(6)
      @services = Service.on_site.includes(:category).order(:name).limit(9)
      @reviews = SiteReview.published.limit(6)
    end

    def sitemap
      @pages = SitePage.published
    end

    def robots
      render plain: "User-agent: *\nAllow: /\nSitemap: #{site_sitemap_url}\n"
    end
  end
end
