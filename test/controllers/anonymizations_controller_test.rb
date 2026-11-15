require "test_helper"

class AnonymizationsControllerTest < ActionDispatch::IntegrationTest
  test "admin anonymizes with a reason, others cannot" do
    sign_in_as users(:advisor)
    post client_anonymization_path(clients(:petrov)), params: { reason: "Заявление" }
    assert_not clients(:petrov).reload.anonymized?

    sign_in_as users(:admin)
    post client_anonymization_path(clients(:petrov)), params: { reason: "" }
    assert_not clients(:petrov).reload.anonymized?
    post client_anonymization_path(clients(:petrov)), params: { reason: "Заявление от 15.11" }
    assert clients(:petrov).reload.anonymized?
    get client_path(clients(:petrov))
    assert_match "Клиент обезличен", response.body
  end

  test "retention run from settings" do
    sign_in_as users(:admin)
    old = Client.create!(last_name: "Старый", phone: "1", created_at: 6.years.ago)
    post anonymize_inactive_path
    assert_not old.reload.anonymized?, "retention not configured"
    ShopSetting.current.update!(pd_retention_years: 5)
    get edit_shop_settings_path
    assert_match "1 клиент без визитов", response.body
    post anonymize_inactive_path
    assert old.reload.anonymized?
  end
end
