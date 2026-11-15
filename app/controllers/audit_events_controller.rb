class AuditEventsController < ApplicationController
  require_permission :admin

  def index
    scope = AuditEvent.includes(:user).recent_first
    scope = scope.where(user_id: params[:user_id]) if params[:user_id].present?
    scope = scope.where(action: params[:event]) if AuditEvent::ACTIONS.include?(params[:event])
    scope = scope.where(created_at: Date.iso8601(params[:from]).beginning_of_day..) if params[:from].present?
    scope = scope.where("subject_label ILIKE ?", "%#{AuditEvent.sanitize_sql_like(params[:q])}%") if params[:q].present?
    respond_to do |format|
      format.html { @pagy, @events = pagy(scope, limit: 50) }
      format.csv do
        send_csv("audit-log", [ t("audit.time"), t("audit.user"), t("audit.action"), t("audit.subject"), t("audit.details"), "IP" ],
                 scope.limit(10_000).map { |e| [ e.created_at, e.user&.name, t("audit.actions.#{e.action}"), e.subject_label, e.details.to_json, e.ip_address ] })
      end
    end
  rescue Date::Error
    redirect_to audit_events_path
  end
end
