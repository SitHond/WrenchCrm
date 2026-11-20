module Site
  class PagesController < BaseController
    def show
      @page = SitePage.published.find_by!(slug: params[:slug])
    end
  end
end
