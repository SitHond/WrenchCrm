class GroupMembership < ApplicationRecord
  belongs_to :group
  belongs_to :person
  belongs_to :group_role

  validates :person_id, uniqueness: { scope: :group_id }
  validate :role_belongs_to_group

  before_validation { self.group_role ||= group&.default_role }

  private
    def role_belongs_to_group
      errors.add(:group_role, :invalid) if group_role && group_role.group_id != group_id
    end
end
