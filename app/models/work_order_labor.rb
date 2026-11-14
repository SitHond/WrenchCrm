class WorkOrderLabor < ApplicationRecord
  include OrderLine

  belongs_to :service, optional: true
  belongs_to :employee, optional: true

  before_validation :copy_from_service, on: :create

  private
    def copy_from_service
      return unless service

      self.name = service.name if name.blank?
      self.price = service.price if price.blank? || price.zero?
    end
end
