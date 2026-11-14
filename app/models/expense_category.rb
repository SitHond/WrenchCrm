class ExpenseCategory < ApplicationRecord
  enum :kind, { expense: 0, income: 1 }

  has_many :cash_operations, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :kind, case_sensitive: false }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }
end
