class ApplicationController < ActionController::Base
  include Authentication
  include Pagy::Backend
  include CsvResponse
  include Auditing

  allow_browser versions: :modern
  stale_when_importmap_changes

  around_action :switch_locale
  helper_method :current_user, :my_due_tasks_count

  rescue_from ActiveRecord::RecordNotFound do
    redirect_to root_path, alert: t("flash.not_found")
  end

  private
    def current_user
      Current.user
    end

    def my_due_tasks_count
      @my_due_tasks_count ||= current_user ? Task.for_user(current_user).due_by(Date.current).count : 0
    end

    def switch_locale(&action)
      locale = current_user&.locale || session[:locale]
      locale = I18n.default_locale unless User::LOCALES.include?(locale.to_s)
      I18n.with_locale(locale, &action)
    end

    def require_permission(permission)
      allowed = permission == :admin ? current_user&.admin? : current_user&.public_send(:"can_#{permission}?")
      redirect_back fallback_location: root_path, alert: t("flash.forbidden") unless allowed
    end

    def self.require_permission(permission, **options)
      before_action(-> { require_permission(permission) }, **options)
    end
end
