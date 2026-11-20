module Site
  class ServicesController < BaseController
    def index
      @groups = Service.on_site.includes(:category).order(:name).group_by { |s| s.category&.name }
    end
  end
end
