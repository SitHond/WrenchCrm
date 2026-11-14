class Employee < ApplicationRecord
  enum :position, { mechanic: 0, service_advisor: 1, manager: 2 }

  belongs_to :user, optional: true
  has_many :work_orders, foreign_key: :mechanic_id, dependent: :nullify, inverse_of: :mechanic
  has_many :appointments, foreign_key: :mechanic_id, dependent: :nullify, inverse_of: :mechanic

  has_many :advised_work_orders, class_name: "WorkOrder", foreign_key: :advisor_id, dependent: :nullify, inverse_of: :advisor
  has_many :salary_payouts, dependent: :restrict_with_error
  has_many :payroll_adjustments, dependent: :destroy

  validates :name, presence: true
  validates :monthly_salary, numericality: { greater_than_or_equal_to: 0 }
  validates :labor_percent, :order_percent, numericality: { in: 0..100 }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }
end
