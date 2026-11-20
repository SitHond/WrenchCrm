# What a visitor sends from the website booking form. Becomes a lead with the website channel.
class Booking
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :name, :string
  attribute :phone, :string
  attribute :vehicle, :string
  attribute :request, :string
  attribute :preferred_time, :string
  attribute :consent, :boolean

  validates :name, presence: true, length: { maximum: 100 }
  validates :phone, presence: true, format: { with: /\A[\d\s()+\-]{6,20}\z/ }
  validates :vehicle, :preferred_time, length: { maximum: 120 }
  validates :request, length: { maximum: 2000 }
  validates :consent, acceptance: { accept: true }

  def to_lead!(ip:)
    text = [ request.presence, (I18n.t("site.booking.preferred", time: preferred_time) if preferred_time.present?) ].compact.join("\n")
    Lead.create!(name: name.strip, phone: phone.strip, vehicle_info: vehicle.presence, request: text.presence, channel: :website,
                 next_contact_on: Date.current, personal_data_consent_at: Time.current, personal_data_consent_ip: ip)
  end
end
