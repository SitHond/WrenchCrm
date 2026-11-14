class Group < ApplicationRecord
  DEFAULT_ROLES = %w[leader member].freeze

  enum :group_type, { ministry: 1, team: 2, bible_study: 3, sunday_school: 4, other: 0 }

  has_many :group_roles, -> { order(:position, :name) }, dependent: :destroy, inverse_of: :group
  has_many :group_memberships, dependent: :destroy
  has_many :people, through: :group_memberships

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  after_create :create_default_roles

  scope :ordered, -> { order(:name) }
  scope :active, -> { where(active: true) }

  def default_role
    group_roles.find_by(default: true) || group_roles.first
  end

  private
    def create_default_roles
      DEFAULT_ROLES.each_with_index do |key, index|
        group_roles.create!(name: I18n.t("groups.default_roles.#{key}"), position: index, default: key == "member")
      end
    end
end
