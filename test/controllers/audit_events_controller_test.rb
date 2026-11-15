require "test_helper"

class AuditEventsControllerTest < ActionDispatch::IntegrationTest
  test "sign-ins, failed sign-ins, client views and exports are logged" do
    post session_path, params: { email_address: "advisor@example.com", password: "wrong" }
    assert_equal "advisor@example.com", AuditEvent.find_by!(action: "login_failed").details["email"]
    post session_path, params: { email_address: "advisor@example.com", password: "password" }
    assert AuditEvent.exists?(action: "login", user: users(:advisor))

    get client_path(clients(:petrov))
    assert AuditEvent.exists?(action: "view", subject: clients(:petrov), user: users(:advisor))
    patch client_path(clients(:petrov)), params: { client: { email: "new@example.com" } }
    assert_equal [ "email" ], AuditEvent.find_by!(action: "update", subject: clients(:petrov)).details["fields"]
    get clients_path(format: :csv)
    assert_equal "clients", AuditEvent.find_by!(action: "export").details["file"]
    get print_work_order_path(work_orders(:open_order), doc: "act")
    assert AuditEvent.exists?(action: "print", subject: work_orders(:open_order))
  end

  test "admin reads and filters the log, others cannot" do
    AuditEvent.record!(:view, subject: clients(:petrov), user: users(:advisor))
    AuditEvent.record!(:login, subject: users(:advisor), user: users(:advisor))
    AuditEvent.record!(:export, user: users(:advisor), file: "clients")
    sign_in_as users(:admin)
    get audit_events_path
    assert_match "Петров Алексей", response.body
    assert_match "advisor@example.com", response.body
    get audit_events_path(event: "view")
    assert_no_match "advisor@example.com", response.body
    get audit_events_path(format: :csv)
    assert_response :success
    sign_in_as users(:advisor)
    get audit_events_path
    assert_redirected_to root_path
  end

  test "idle sessions expire" do
    sign_in_as users(:advisor)
    Current.session.update_column(:updated_at, 15.days.ago)
    get clients_path
    assert_redirected_to new_session_path
  end

  test "deactivated users lose their session" do
    sign_in_as users(:advisor)
    users(:advisor).update!(active: false)
    get clients_path
    assert_redirected_to new_session_path
  end
end
