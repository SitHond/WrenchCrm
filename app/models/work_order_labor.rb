class WorkOrderLabor < ApplicationRecord
  include OrderLine

  belongs_to :service, optional: true
  has_many :performers, class_name: "WorkOrderLaborPerformer", dependent: :destroy
  has_many :employees, through: :performers

  # Set when adding a line: that employee does the whole job.
  attr_accessor :employee, :save_to_catalog

  before_validation :copy_from_service, on: :create
  before_create :create_catalog_service, if: -> { save_to_catalog.to_s == "1" && service.nil? }
  after_create { performers.create!(employee: employee, share: 100) if employee }

  def employee_id=(id)
    self.employee = Employee.find_by(id: id)
  end

  def performers_label
    performers.map { |p| p.share == 100 ? p.employee.name : "#{p.employee.name} #{p.share.to_i}%" }.join(", ")
  end

  private
    def copy_from_service
      return unless service

      self.name = service.name if name.blank?
      self.price = service.price_for(work_order&.complexity_level) if price.blank? || price.zero?
    end

    def create_catalog_service
      self.service = Service.create!(name: name, price: price)
    end
end
