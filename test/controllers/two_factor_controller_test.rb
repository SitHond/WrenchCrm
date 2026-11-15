require "test_helper"

class TwoFactorControllerTest < ActionDispatch::IntegrationTest
  def enable_for(user)
    secret = User.new_secret_for_setup
    codes = user.enable_two_factor!(secret, ROTP::TOTP.new(secret).now)
    [ secret, codes ]
  end

  test "set up from the profile" do
    sign_in_as users(:advisor)
    get new_two_factor_path
    assert_select ".qr svg"
    secret = session[:otp_setup_secret]
    post two_factor_path, params: { code: "000000" }
    assert_not users(:advisor).reload.two_factor_enabled?
    post two_factor_path, params: { code: ROTP::TOTP.new(secret).now }
    assert users(:advisor).reload.two_factor_enabled?
    assert_select ".backup-codes li", count: 8
    assert_not_equal secret, users(:advisor).read_attribute_before_type_cast(:otp_secret), "stored encrypted"
  end

  test "sign-in asks for a code, codes work once, backup codes work once" do
    secret, codes = enable_for(users(:advisor))
    users(:advisor).update_column(:otp_last_timestep, nil)
    post session_path, params: { email_address: "advisor@example.com", password: "password" }
    assert_redirected_to two_factor_session_path
    assert_nil cookies[:session_id].presence
    post verify_session_path, params: { code: "123456" }
    assert_redirected_to two_factor_session_path
    code = ROTP::TOTP.new(secret).now
    post verify_session_path, params: { code: code }
    assert_redirected_to root_path
    assert AuditEvent.exists?(action: "login", user: users(:advisor))

    delete session_path
    post session_path, params: { email_address: "advisor@example.com", password: "password" }
    post verify_session_path, params: { code: code }
    assert_redirected_to two_factor_session_path, "the same code cannot be reused"
    post verify_session_path, params: { code: codes.first }
    assert_redirected_to root_path
    assert_equal 7, users(:advisor).reload.backup_codes_left
  end

  test "required setting forces setup, admin can reset" do
    ShopSetting.current.update!(require_two_factor: true)
    sign_in_as users(:viewer)
    get clients_path
    assert_redirected_to new_two_factor_path

    enable_for(users(:viewer))
    sign_in_as users(:admin)
    enable_for(users(:admin))
    delete two_factor_admin_user_path(users(:viewer))
    assert_not users(:viewer).reload.two_factor_enabled?
  end
end
