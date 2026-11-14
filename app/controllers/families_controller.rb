class FamiliesController < ApplicationController
  before_action :set_family, only: %i[ show edit update destroy ]
  require_permission :add_records, only: %i[ new create ]
  require_permission :edit_records, only: %i[ edit update ]
  require_permission :delete_records, only: :destroy

  def index
    scope = Family.search(params[:q])
    scope = params[:status] == "inactive" ? scope.inactive : scope.active
    @pagy, @families = pagy(scope.ordered.includes(:people), limit: 25)
  end

  def show
    @notes = @family.notes.visible_to(current_user).recent_first.includes(:author)
  end

  def new
    @family = Family.new
  end

  def create
    @family = Family.new(family_params)
    if @family.save
      redirect_to @family, notice: t("flash.created", model: Family.model_name.human)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @family.update(family_params)
      redirect_to @family, notice: t("flash.updated", model: Family.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @family.destroy
    redirect_to families_path, notice: t("flash.destroyed", model: Family.model_name.human), status: :see_other
  end

  private
    def set_family
      @family = Family.find(params[:id])
    end

    def family_params
      params.expect(family: [
        :name, :address1, :address2, :city, :state, :zip, :country, :home_phone, :email,
        :wedding_date, :send_newsletter, :deactivated_on
      ])
    end
end
