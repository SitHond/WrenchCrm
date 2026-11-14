require "test_helper"

class GroupsControllerTest < ActionDispatch::IntegrationTest
  test "group manager adds and removes members" do
    sign_in_as users(:admin)
    group = groups(:youth)

    post group_group_memberships_path(group), params: { group_membership: { person_id: people(:guest).id } }
    membership = group.group_memberships.find_by!(person: people(:guest))
    assert_equal group_roles(:youth_member), membership.group_role

    patch group_group_membership_path(group, membership), params: { group_membership: { group_role_id: group_roles(:youth_leader).id } }
    assert_equal group_roles(:youth_leader), membership.reload.group_role

    delete group_group_membership_path(group, membership)
    assert_not GroupMembership.exists?(membership.id)
  end

  test "editor without manage_groups cannot change groups" do
    sign_in_as users(:editor)
    assert_no_difference(-> { Group.count }) { post groups_path, params: { group: { name: "Новая" } } }
    assert_no_difference(-> { GroupMembership.count }) do
      post group_group_memberships_path(groups(:youth)), params: { group_membership: { person_id: people(:guest).id } }
    end
  end

  test "role in use cannot be deleted" do
    sign_in_as users(:admin)
    assert_no_difference(-> { GroupRole.count }) { delete group_group_role_path(groups(:youth), group_roles(:youth_leader)) }
  end

  test "show lists members" do
    sign_in_as users(:viewer)
    get group_path(groups(:youth))
    assert_select "td a", text: "Иванов Сергей"
  end
end
