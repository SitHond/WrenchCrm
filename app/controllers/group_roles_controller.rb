class GroupRolesController < ApplicationController
  require_permission :manage_groups
  before_action :set_group

  def create
    role = @group.group_roles.new(params.expect(group_role: [ :name ]))
    role.position = @group.group_roles.maximum(:position).to_i + 1
    if role.save
      redirect_to edit_group_path(@group), notice: t("flash.created", model: GroupRole.model_name.human)
    else
      redirect_to edit_group_path(@group), alert: role.errors.full_messages.to_sentence
    end
  end

  def update
    @group.group_roles.find(params[:id]).update!(default: true)
    redirect_to edit_group_path(@group), notice: t("flash.updated", model: GroupRole.model_name.human)
  end

  def destroy
    role = @group.group_roles.find(params[:id])
    if role.destroy
      redirect_to edit_group_path(@group), notice: t("flash.destroyed", model: GroupRole.model_name.human), status: :see_other
    else
      redirect_to edit_group_path(@group), alert: role.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private
    def set_group
      @group = Group.find(params[:group_id])
    end
end
