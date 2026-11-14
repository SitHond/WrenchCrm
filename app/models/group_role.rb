class GroupRole < ApplicationRecord
  belongs_to :group
  has_many :group_memberships, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :group_id, case_sensitive: false }

  before_save :unset_other_defaults, if: -> { default? && will_save_change_to_default? }

  private
    def unset_other_defaults
      group.group_roles.where.not(id: id).update_all(default: false)
    end
end
