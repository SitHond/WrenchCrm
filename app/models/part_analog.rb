class PartAnalog < ApplicationRecord
  belongs_to :part
  belongs_to :analog, class_name: "Part"

  validates :analog_id, uniqueness: { scope: :part_id }
  validate :not_self

  def self.link!(part, analog)
    return if part == analog || exists?(part: analog, analog: part)

    find_or_create_by!(part: part, analog: analog)
  end

  def self.unlink!(part, analog)
    where(part: part, analog: analog).or(where(part: analog, analog: part)).destroy_all
  end

  private
    def not_self
      errors.add(:analog, :invalid) if part_id == analog_id
    end
end
