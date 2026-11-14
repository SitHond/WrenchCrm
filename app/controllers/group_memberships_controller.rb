class GroupMembershipsController < ApplicationController
  require_permission :manage_groups
  before_action :set_group

  def create
    membership = @group.group_memberships.new(params.expect(group_membership: [ :person_id, :group_role_id ]))
    if membership.save
      redirect_back fallback_location: @group, notice: t("group_memberships.added", person: membership.person.short_name)
    else
      redirect_back fallback_location: @group, alert: membership.errors.full_messages.to_sentence
    end
  end

  def update
    membership = @group.group_memberships.find(params[:id])
    membership.update(params.expect(group_membership: [ :group_role_id ]))
    redirect_back fallback_location: @group, notice: t("flash.updated", model: GroupMembership.model_name.human)
  end

  def destroy
    membership = @group.group_memberships.find(params[:id])
    membership.destroy
    redirect_back fallback_location: @group, notice: t("group_memberships.removed", person: membership.person.short_name), status: :see_other
  end

  private
    def set_group
      @group = Group.find(params[:group_id])
    end
end
