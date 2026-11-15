# Time-based one-time codes (RFC 6238) from an authenticator app, plus single-use backup codes.
module TwoFactor
  extend ActiveSupport::Concern

  ISSUER = "WrenchCRM".freeze
  BACKUP_CODES = 8

  included do
    encrypts :otp_secret
  end

  def two_factor_enabled? = otp_enabled_at.present?

  class_methods do
    def new_secret_for_setup = ROTP::Base32.random
  end

  def provisioning_uri(secret)
    ROTP::TOTP.new(secret, issuer: ISSUER).provisioning_uri(email_address)
  end

  # Turns two-factor sign-in on when `code` matches `secret`; returns plain backup codes to show once.
  def enable_two_factor!(secret, code)
    timestep = ROTP::TOTP.new(secret).verify(code.to_s.delete(" "), drift_behind: 30, drift_ahead: 30)
    return unless timestep

    codes = Array.new(BACKUP_CODES) { SecureRandom.alphanumeric(10).downcase }
    update!(otp_secret: secret, otp_enabled_at: Time.current, otp_last_timestep: timestep,
            otp_backup_codes: codes.map { |c| BCrypt::Password.create(c) })
    codes
  end

  def disable_two_factor!
    update!(otp_secret: nil, otp_enabled_at: nil, otp_last_timestep: nil, otp_backup_codes: [])
  end

  # Accepts a current app code (each code once) or an unused backup code.
  def verify_two_factor(code)
    code = code.to_s.strip.downcase.delete(" -")
    return false if code.empty? || !two_factor_enabled?

    if code.match?(/\A\d{6}\z/)
      timestep = ROTP::TOTP.new(otp_secret).verify(code, drift_behind: 30, drift_ahead: 30, after: otp_last_timestep)
      timestep ? update!(otp_last_timestep: timestep) && true : false
    else
      index = otp_backup_codes.index { |digest| BCrypt::Password.new(digest) == code }
      index ? update!(otp_backup_codes: otp_backup_codes.dup.tap { |c| c.delete_at(index) }) && true : false
    end
  end

  def backup_codes_left = otp_backup_codes.size
end
