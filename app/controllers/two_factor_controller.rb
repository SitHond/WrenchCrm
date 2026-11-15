# Turning two-factor sign-in on and off from the profile.
class TwoFactorController < ApplicationController
  skip_before_action :require_two_factor_setup

  def new
    session[:otp_setup_secret] ||= User.new_secret_for_setup
    @secret = session[:otp_setup_secret]
    @qr = RQRCode::QRCode.new(current_user.provisioning_uri(@secret)).as_svg(module_size: 4, standalone: true, use_path: true)
  end

  def create
    codes = current_user.enable_two_factor!(session[:otp_setup_secret].to_s, params[:code])
    if codes
      session.delete(:otp_setup_secret)
      audit(:two_factor, current_user, change: "enabled")
      @codes = codes
      render :backup_codes
    else
      redirect_to new_two_factor_path, alert: t("two_factor.invalid")
    end
  end

  def destroy
    if current_user.authenticate(params[:password].to_s) && current_user.verify_two_factor(params[:code])
      current_user.disable_two_factor!
      audit(:two_factor, current_user, change: "disabled")
      redirect_to edit_profile_path, notice: t("two_factor.disabled")
    else
      redirect_to edit_profile_path, alert: t("two_factor.disable_failed")
    end
  end
end
