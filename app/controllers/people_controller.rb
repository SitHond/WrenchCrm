class PeopleController < ApplicationController
  before_action :set_person, only: %i[ show edit update destroy ]
  require_permission :add_records, only: %i[ new create ]
  require_permission :edit_records, only: %i[ edit update ]
  require_permission :delete_records, only: :destroy

  def index
    scope = Person.includes(:family).search(params[:q])
    scope = scope.where(classification: params[:classification]) if Person.classifications.key?(params[:classification])
    scope = params[:status] == "inactive" ? scope.inactive : scope.active
    @pagy, @people = pagy(scope.ordered, limit: 25)
  end

  def show
    @notes = @person.notes.visible_to(current_user).recent_first.includes(:author)
    @memberships = @person.group_memberships.includes(:group, :group_role)
    @available_groups = Group.active.ordered.where.not(id: @memberships.map(&:group_id))
  end

  def new
    family = Family.find_by(id: params[:family_id])
    @person = Person.new(family: family, last_name: family&.name)
  end

  def create
    @person = Person.new(person_params)
    if @person.save
      redirect_to @person, notice: t("flash.created", model: Person.model_name.human)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @person.update(person_params)
      redirect_to @person, notice: t("flash.updated", model: Person.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @person.destroy
    redirect_to people_path, notice: t("flash.destroyed", model: Person.model_name.human), status: :see_other
  end

  private
    def set_person
      @person = Person.find(params[:id])
    end

    def person_params
      params.expect(person: [
        :family_id, :title, :first_name, :middle_name, :last_name, :suffix, :gender, :family_role,
        :classification, :birth_day, :birth_month, :birth_year, :membership_date, :friend_date,
        :deceased_on, :email, :work_email, :cell_phone, :home_phone, :work_phone,
        :address1, :address2, :city, :state, :zip, :country, :facebook, :telegram, :deactivated_on
      ])
    end
end
