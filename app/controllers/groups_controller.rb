class GroupsController < ApplicationController
  before_action :set_group, only: %i[ show edit update destroy ]
  require_permission :manage_groups, except: %i[ index show ]

  def index
    @groups = Group.ordered.left_joins(:group_memberships)
      .select("groups.*, COUNT(group_memberships.id) AS members_count").group("groups.id")
    @groups = @groups.where(group_type: params[:group_type]) if Group.group_types.key?(params[:group_type])
  end

  def show
    @memberships = @group.group_memberships.includes(:person, :group_role)
      .joins(:person).order("group_roles.position", "people.last_name", "people.first_name").references(:group_role)
    @candidates = Person.active.ordered.where.not(id: @memberships.map(&:person_id))
  end

  def new
    @group = Group.new
  end

  def create
    @group = Group.new(group_params)
    if @group.save
      redirect_to @group, notice: t("flash.created", model: Group.model_name.human)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @group.update(group_params)
      redirect_to @group, notice: t("flash.updated", model: Group.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @group.destroy
    redirect_to groups_path, notice: t("flash.destroyed", model: Group.model_name.human), status: :see_other
  end

  private
    def set_group
      @group = Group.find(params[:id])
    end

    def group_params
      params.expect(group: [ :name, :description, :group_type, :active, :include_in_email_export ])
    end
end
