require "test_helper"

class SiteTest < ActionDispatch::IntegrationTest
  setup do
    ShopSetting.current.update!(name: "Гайка", phone: "+7 900 000-00-00", address: "Москва, ул. Примерная, 1", legal_name: "ООО «Гайка»")
    services(:oil_change).update!(show_on_site: true, site_description: "Масло и фильтр")
  end

  test "public pages render without signing in" do
    get site_root_path
    assert_response :success
    assert_match "Гайка", response.body
    assert_match "Замена масла", response.body
    get site_services_path
    assert_match "от 1 200 ₽", response.body
    get site_contacts_path
    assert_match "yandex.ru/map-widget", response.body
    get site_privacy_path
    assert_match "Политика обработки персональных данных", response.body
    get site_sitemap_path
    assert_match "<urlset", response.body
    get site_robots_path
    assert_match "Sitemap:", response.body
  end

  test "booking needs consent, ignores bots and creates a website lead" do
    assert_no_difference(-> { Lead.count }) do
      post site_booking_path, params: { booking: { name: "Иван", phone: "+7 999 111-22-33", consent: "0" } }
    end
    assert_response :unprocessable_entity
    assert_no_difference(-> { Lead.count }) do
      post site_booking_path, params: { website: "spam", booking: { name: "Bot", phone: "+7 999 111-22-33", consent: "1" } }
    end
    assert_difference(-> { Lead.count }) do
      post site_booking_path, params: { booking: { name: "Иван", phone: "+7 999 111-22-33", vehicle: "Kia Rio", request: "ТО", preferred_time: "суббота", consent: "1" } }
    end
    lead = Lead.last
    assert lead.channel_website?
    assert lead.personal_data_consent_at
    assert_match "суббота", lead.request
    assert_redirected_to site_new_booking_path(sent: 1)
  end

  test "pages, disabled site and unknown pages" do
    SitePage.create!(title: "О сервисе", slug: "about", body: "Работаем с 2010 года")
    get site_page_path("about")
    assert_match "Работаем с 2010 года", response.body
    get site_page_path("missing")
    assert_response :not_found
    SiteSetting.current.update!(enabled: false)
    get site_root_path
    assert_response :service_unavailable
  end

  test "site host serves the site at the root and keeps the CRM off it" do
    with_env("SITE_HOST" => "gayka.ru") do
      Rails.application.reload_routes!
      host! "gayka.ru"
      get "/"
      assert_match "Записаться", response.body
      get "/clients"
      assert_response :not_found
      host! "www.gayka.ru"
      get "/services"
      assert_response :success
      host! "crm.gayka.ru"
      get "/"
      assert_redirected_to "/session/new"
    end
  ensure
    Rails.application.reload_routes!
  end

  private
    def with_env(vars)
      old = vars.keys.to_h { |k| [ k, ENV[k] ] }
      vars.each { |k, v| ENV[k] = v }
      yield
    ensure
      old.each { |k, v| ENV[k] = v }
    end
end
