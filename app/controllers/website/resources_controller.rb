module Website
  # Shared list / create / edit / delete for banners, pages, promotions and reviews.
  class ResourcesController < ApplicationController
    require_permission :manage_site
    before_action :set_record, only: %i[ edit update destroy ]
    helper_method :resource_class, :resource_name

    def index
      @records = scope.to_a
      render "website/resources/index"
    end

    def new
      @record = resource_class.new(defaults)
      render "website/resources/new"
    end

    def create
      @record = resource_class.new(record_params)
      if @record.save
        redirect_to url_for(action: :index), notice: t("flash.created", model: resource_class.model_name.human)
      else
        render "website/resources/new", status: :unprocessable_entity
      end
    end

    def edit
      render "website/resources/edit"
    end

    def update
      @record.image.purge if params[:remove_image] == "1" && @record.respond_to?(:image)
      if @record.update(record_params)
        redirect_to url_for(action: :index), notice: t("flash.updated", model: resource_class.model_name.human)
      else
        render "website/resources/edit", status: :unprocessable_entity
      end
    end

    def destroy
      @record.destroy
      redirect_to url_for(action: :index), notice: t("flash.destroyed", model: resource_class.model_name.human), status: :see_other
    end

    private
      def resource_name = controller_name.singularize

      def set_record
        @record = resource_class.find(params[:id])
      end

      def defaults = {}

      def record_params
        params.expect(resource_class.model_name.param_key => permitted)
      end
  end
end
