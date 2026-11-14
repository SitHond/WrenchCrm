require "test_helper"

class GroupTest < ActiveSupport::TestCase
  test "new group gets leader and member roles" do
    group = Group.create!(name: "Хор")
    assert_equal 2, group.group_roles.count
    assert group.default_role.default?
  end

  test "membership defaults to the group default role" do
    membership = groups(:youth).group_memberships.create!(person: people(:guest))
    assert_equal group_roles(:youth_member), membership.group_role
  end

  test "person can join a group only once" do
    membership = groups(:youth).group_memberships.new(person: people(:sergey))
    assert_not membership.valid?
  end

  test "role from another group is rejected" do
    other = Group.create!(name: "Хор")
    membership = groups(:youth).group_memberships.new(person: people(:guest), group_role: other.default_role)
    assert_not membership.valid?
  end

  test "only one default role per group" do
    group_roles(:youth_leader).update!(default: true)
    assert_not group_roles(:youth_member).reload.default?
  end
end
