require "test_helper"

class ConsentsControllerTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:advisor) }

  test "print form, record and withdraw a consent" do
    ShopSetting.current.update!(legal_name: "ООО «Гайка»", address: "Москва, ул. Примерная, 1")
    get print_client_consents_path(clients(:petrov), kind: "personal_data")
    assert_match "Согласие на обработку персональных данных", response.body
    assert_match "ООО «Гайка»", response.body
    assert_match "Петров Алексей", response.body

    get work_order_path(work_orders(:open_order))
    assert_match "нет отдельного согласия", response.body

    post client_consents_path(clients(:petrov)), params: { consent: { kind: "personal_data", channel: "paper" } }
    consent = clients(:petrov).consents.sole
    assert_equal Consent.version_for(:personal_data), consent.text_version
    assert_equal users(:advisor), consent.recorded_by
    assert clients(:petrov).reload.personal_data_consent?
    assert AuditEvent.exists?(action: "consent_given", subject: clients(:petrov))
    get work_order_path(work_orders(:open_order))
    assert_no_match "нет отдельного согласия", response.body

    patch withdraw_client_consent_path(clients(:petrov), consent), params: { reason: "" }
    assert consent.reload.active?
    patch withdraw_client_consent_path(clients(:petrov), consent), params: { reason: "Заявление от 15.11" }
    assert_not consent.reload.active?
    assert_not clients(:petrov).reload.personal_data_consent?
  end

  test "custom text changes the version and filter finds clients without consent" do
    old = Consent.version_for(:personal_data)
    ShopSetting.current.update!(pd_consent_text: "Свой текст")
    assert_not_equal old, Consent.version_for(:personal_data)
    clients(:taxi).consents.create!(kind: :personal_data)
    get clients_path(consent: "missing")
    assert_select "a", text: "Петров Алексей"
    assert_select "a", text: "ООО Такси", count: 0
  end

  test "settings page renders in both languages" do
    sign_in_as users(:admin)
    get edit_shop_settings_path
    assert_response :success
    users(:admin).update!(locale: "en")
    get edit_shop_settings_path
    assert_response :success
  end

  test "viewer can print but not record" do
    sign_in_as users(:viewer)
    get print_client_consents_path(clients(:petrov), kind: "marketing")
    assert_response :success
    post client_consents_path(clients(:petrov)), params: { consent: { kind: "marketing", channel: "paper" } }
    assert_empty clients(:petrov).consents
  end
end
