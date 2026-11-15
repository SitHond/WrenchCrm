module Auditing
  extend ActiveSupport::Concern

  private
    def audit(action, subject = nil, **details)
      AuditEvent.record!(action, subject: subject, ip: request.remote_ip, **details)
    end

    def audit_changes(record)
      record.saved_changes.keys - %w[updated_at created_at]
    end
end
