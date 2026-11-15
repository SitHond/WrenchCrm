require "test_helper"

class PrivacyControllerTest < ActionDispatch::IntegrationTest
  test "public policy with shop requisites, custom text wins" do
    ShopSetting.current.update!(legal_name: "ООО «Гайка»", inn: "7701234567", email: "info@example.com")
    get privacy_policy_path
    assert_response :success
    assert_match "Политика обработки персональных данных", response.body
    assert_match "ООО «Гайка»", response.body
    assert_match "info@example.com", response.body
    ShopSetting.current.update!(privacy_policy_text: "Свой текст политики")
    get privacy_policy_path
    assert_match "Свой текст политики", response.body
  end

  test "linked from the sign-in page" do
    get new_session_path
    assert_select "a[href=?]", privacy_policy_path
  end
end
