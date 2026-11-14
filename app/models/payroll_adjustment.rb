class PayrollAdjustment < ApplicationRecord
  belongs_to :employee
  belongs_to :created_by, class_name: "User", optional: true

  validates :amount, numericality: { other_than: 0 }
  validates :comment, :period, presence: true

  before_validation { self.period = period&.beginning_of_month }
  before_create { self.created_by ||= Current.user }
end
