module Deactivatable
  extend ActiveSupport::Concern

  included do
    scope :active, -> { where(deactivated_on: nil) }
    scope :inactive, -> { where.not(deactivated_on: nil) }
  end

  def active?
    deactivated_on.nil?
  end
end
