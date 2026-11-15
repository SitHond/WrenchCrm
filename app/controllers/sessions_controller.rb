class SessionsController < ApplicationController
  skip_before_action :require_two_factor_setup
  allow_unauthenticated_access only: %i[ new create two_factor verify ]
  rate_limit to: 10, within: 3.minutes, only: %i[ create verify ], with: -> { redirect_to new_session_path, alert: t("sessions.rate_limited") }

  layout "auth"

  def new
  end

  def create
    user = User.active.authenticate_by(params.permit(:email_address, :password))
    if user&.two_factor_enabled?
      session[:pending_two_factor] = { "user_id" => user.id, "at" => Time.current.to_i }
      redirect_to two_factor_session_path
    elsif user
      complete_sign_in(user)
    else
      AuditEvent.record!(:login_failed, user: nil, ip: request.remote_ip, email: params[:email_address].to_s.strip.downcase.first(100))
      redirect_to new_session_path, alert: t("sessions.invalid")
    end
  end

  PENDING_TTL = 5.minutes

  def two_factor
    redirect_to new_session_path unless pending_user
  end

  def verify
    user = pending_user
    return redirect_to(new_session_path, alert: t("two_factor.expired")) unless user

    if user.verify_two_factor(params[:code])
      session.delete(:pending_two_factor)
      complete_sign_in(user, two_factor: true)
    else
      AuditEvent.record!(:login_failed, user: user, ip: request.remote_ip, step: "two_factor")
      redirect_to two_factor_session_path, alert: t("two_factor.invalid")
    end
  end

  def destroy
    audit(:logout, Current.user)
    terminate_session
    redirect_to new_session_path, status: :see_other
  end

  private
    def pending_user
      pending = session[:pending_two_factor]
      return unless pending && Time.at(pending["at"].to_i) > PENDING_TTL.ago

      User.active.find_by(id: pending["user_id"])
    end

    def complete_sign_in(user, two_factor: false)
      user.record_login!
      start_new_session_for user
      audit(:login, user, two_factor: two_factor || nil)
      redirect_to after_authentication_url
    end
end
