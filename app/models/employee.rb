class Employee < ApplicationRecord
  enum :position, { mechanic: 0, service_advisor: 1, manager: 2 }

  belongs_to :user, optional: true
  has_many :work_orders, foreign_key: :mechanic_id, dependent: :nullify, inverse_of: :mechanic
  has_many :appointments, foreign_key: :mechanic_id, dependent: :nullify, inverse_of: :mechanic

  validates :name, presence: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }
end
