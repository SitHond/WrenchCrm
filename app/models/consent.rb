# A client's consent to personal data processing (152-FZ art. 9) or to advertising messages (38-FZ art. 18).
class Consent < ApplicationRecord
  enum :kind, { personal_data: 0, marketing: 1 }
  enum :channel, { paper: 0, electronic: 1 }

  belongs_to :client
  belongs_to :recorded_by, class_name: "User", optional: true
  belongs_to :withdrawn_by, class_name: "User", optional: true

  validates :given_at, presence: true
  validates :withdrawal_reason, presence: true, if: :withdrawn_at?

  before_validation { self.given_at ||= Time.current }
  before_create { self.recorded_by ||= Current.user }

  scope :active, -> { where(withdrawn_at: nil) }

  def active? = withdrawn_at.nil?

  def withdraw!(reason)
    update!(withdrawn_at: Time.current, withdrawn_by: Current.user, withdrawal_reason: reason)
  end

  def self.text_for(kind)
    setting = ShopSetting.current
    custom = kind.to_s == "marketing" ? setting.marketing_consent_text : setting.pd_consent_text
    custom.presence || I18n.t("consents.default_text.#{kind}", locale: :ru)
  end

  # Short fingerprint of the consent text the client signed.
  def self.version_for(kind)
    Digest::SHA256.hexdigest(text_for(kind))[0, 8]
  end
end
