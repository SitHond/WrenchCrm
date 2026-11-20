require "test_helper"

class WebsiteAdminTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:admin) }

  def image_upload
    Rack::Test::UploadedFile.new(StringIO.new(Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==")), "image/png", original_filename: "b.png")
  end

  test "settings with logo and theme show up on the public site" do
    get edit_website_settings_path
    assert_response :success
    patch website_settings_path, params: { site_setting: { title: "Гайка", tagline: "Чиним быстро", theme: "blue", logo: image_upload } }
    assert SiteSetting.current.logo.attached?
    get site_root_path
    assert_match "Чиним быстро", response.body
    assert_select "body.site-theme-blue"
  end

  test "banners, promotions, pages and reviews are managed and shown" do
    post website_banners_path, params: { site_banner: { title: "Шиномонтаж без очереди", button_text: "Записаться", image: image_upload } }
    post website_promotions_path, params: { site_promotion: { title: "Скидка 10%", ends_on: 1.week.from_now.to_date } }
    post website_promotions_path, params: { site_promotion: { title: "Прошедшая акция", ends_on: Date.yesterday } }
    post website_pages_path, params: { site_page: { title: "Гарантия", slug: "warranty", body: "Полгода на работы" } }
    post website_reviews_path, params: { site_review: { author: "Ольга", text: "Всё отлично", rating: 5 } }
    get website_banners_path
    assert_select "td a", text: "Шиномонтаж без очереди"

    get site_root_path
    assert_match "Шиномонтаж без очереди", response.body
    assert_match "Скидка 10%", response.body
    assert_no_match "Прошедшая акция", response.body
    assert_match "Всё отлично", response.body
    assert_select ".site-nav a", text: "Гарантия"
    get site_page_path("warranty")
    assert_match "Полгода на работы", response.body

    banner = SiteBanner.last
    patch website_banner_path(banner), params: { site_banner: { active: "0" } }
    get site_root_path
    assert_no_match "Шиномонтаж без очереди", response.body
    delete website_banner_path(banner)
    assert_not SiteBanner.exists?(banner.id)
  end

  test "only users with website permission" do
    sign_in_as users(:advisor)
    get edit_website_settings_path
    assert_redirected_to root_path
    users(:advisor).update!(manage_site: true)
    get website_pages_path
    assert_response :success
  end

  test "non-images are rejected" do
    post website_banners_path, params: { site_banner: { title: "X", image: Rack::Test::UploadedFile.new(StringIO.new("not an image"), "text/plain", original_filename: "x.txt") } }
    assert_response :unprocessable_entity
  end
end
