class ServicesController < ApplicationController
  before_action :set_service, only: %i[ edit update destroy ]
  require_permission :manage_catalog, except: :index

  def index
    scope = Service.search(params[:q]).includes(:category)
    scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?
    scope = scope.active unless params[:status] == "all"
    @pagy, @services = pagy(scope.ordered, limit: 50)
  end

  def new
    @service = Service.new
  end

  def create
    @service = Service.new(service_params)
    if @service.save
      redirect_to services_path, notice: t("flash.created", model: Service.model_name.human)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @service.update(service_params)
      redirect_to services_path, notice: t("flash.updated", model: Service.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @service.destroy
    redirect_to services_path, notice: t("flash.destroyed", model: Service.model_name.human), status: :see_other
  end

  private
    def set_service
      @service = Service.find(params[:id])
    end

    def service_params
      params.expect(service: [ :name, :code, :norm_hours, :price, :active, :category_id, prices_attributes: [ [ :id, :complexity_level_id, :price, :_destroy ] ] ])
    end
end
