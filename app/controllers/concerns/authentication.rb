module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    def authenticated?
      resume_session
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      Current.session ||= find_session_by_cookie
    end

    IDLE_TIMEOUT = 14.days

    # Sessions end after two weeks without activity; activity is recorded at most every few minutes.
    def find_session_by_cookie
      session = Session.includes(:user).find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
      return unless session

      if session.updated_at < IDLE_TIMEOUT.ago || !session.user.active?
        session.destroy
        cookies.delete(:session_id)
        return
      end
      session.touch if session.updated_at < 5.minutes.ago
      session
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.url
      redirect_to new_session_path
    end

    def after_authentication_url
      session.delete(:return_to_after_authenticating) || root_url
    end

    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }
      end
    end

    def terminate_session
      Current.session.destroy
      cookies.delete(:session_id)
    end
end
