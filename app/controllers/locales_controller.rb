class LocalesController < ApplicationController
  skip_before_action :require_two_factor_setup
  allow_unauthenticated_access

  def update
    locale = params[:locale].to_s
    if User::LOCALES.include?(locale)
      session[:locale] = locale
      resume_session&.user&.update(locale: locale)
    end
    redirect_back fallback_location: root_path
  end
end
