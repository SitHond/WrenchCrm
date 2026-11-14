module Admin
  class BaysController < ApplicationController
    require_permission :admin
    before_action :set_bay, only: %i[ edit update destroy ]

    def index
      @bays = Bay.ordered
    end

    def new
      @bay = Bay.new(position: Bay.maximum(:position).to_i + 1)
    end

    def create
      @bay = Bay.new(bay_params)
      if @bay.save
        redirect_to admin_bays_path, notice: t("flash.created", model: Bay.model_name.human)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @bay.update(bay_params)
        redirect_to admin_bays_path, notice: t("flash.updated", model: Bay.model_name.human)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @bay.destroy
      redirect_to admin_bays_path, notice: t("flash.destroyed", model: Bay.model_name.human), status: :see_other
    end

    private
      def set_bay
        @bay = Bay.find(params[:id])
      end

      def bay_params
        params.expect(bay: [ :name, :position, :active ])
      end
  end
end
