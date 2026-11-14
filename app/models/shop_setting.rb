# Single row with shop-wide settings and the requisites printed on documents.
class ShopSetting < ApplicationRecord
  validates :inn, format: { with: /\A\d{10}(\d{2})?\z/ }, allow_blank: true
  validates :bik, format: { with: /\A\d{9}\z/ }, allow_blank: true
  validates :bank_account, :correspondent_account, format: { with: /\A\d{20}\z/ }, allow_blank: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  def self.current
    first || create!(name: ENV.fetch("SHOP_NAME", "WrenchCRM"), address: ENV["SHOP_DETAILS"])
  end

  def display_name
    name.presence || legal_name.presence || I18n.t("app.name")
  end

  def requisites_line
    [ legal_name, ("ИНН #{inn}" if inn.present?), ("КПП #{kpp}" if kpp.present?), address, phone ].compact_blank.join(", ")
  end

  def bank_details?
    bank_name.present? && bik.present? && bank_account.present?
  end
end
