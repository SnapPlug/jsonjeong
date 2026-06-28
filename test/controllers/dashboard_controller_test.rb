require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "homepage renders with structured data and FAQ" do
    get "/"
    assert_response :success
    # Site-wide JSON-LD + page FAQPage JSON-LD
    assert_match "application/ld+json", response.body
    assert_match '"@type":"FAQPage"', response.body
    assert_match '"@type":"Person"', response.body
    # FAQ content is present in the DOM (collapsible, but crawlable)
    assert_match "내 바이브코딩 앱이 안전한지 어떻게 알 수 있나요?", response.body
  end
end
