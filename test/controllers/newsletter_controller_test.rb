require "test_helper"

class NewsletterControllerTest < ActionDispatch::IntegrationTest
  # 메인(jsonjeong.com) 옆 구독 칸은 /newsletter로 보내고, 저장 뒤 newsletter 하위 도메인으로 넘긴다.
  # 다른 호스트라 allow_other_host가 없으면 OpenRedirectError로 500이 났다 (2026-10-18).
  test "apex sidebar subscribe redirects to newsletter subdomain" do
    host! "example.com"
    assert_difference -> { Subscriber.count }, 1 do
      post "/newsletter", params: { email: "reader-#{SecureRandom.hex(4)}@example.com", source: "sidebar" }
    end
    assert_redirected_to "http://newsletter.example.com/"
  end

  test "apex /newsletter sends people to the snapplug.app newsletter" do
    get "/newsletter"
    assert_redirected_to SNAPPLUG_NEWSLETTER_URL
  end

  test "homepage links to the snapplug.app newsletter" do
    get "/"
    assert_select "a[href=?]", SNAPPLUG_NEWSLETTER_URL
  end

  test "homepage links to the snapplug.app cases" do
    get "/"
    assert_select "a[href=?]", "https://snapplug.app/cases"
  end
end
