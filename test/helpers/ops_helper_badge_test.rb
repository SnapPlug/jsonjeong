require "test_helper"

class OpsHelperBadgeTest < ActionView::TestCase
  include OpsHelper

  test "플랫폼 소식 로고는 서비스마다 있다" do
    PlatformEvent::SOURCES.each_key { |source| assert_includes platform_icon(source), "<svg", source }
  end

  test "URL 배지는 응답하는 것으로 고른다" do
    assert_equal "Next.js", check_badge(Client.new(kind: "vercel_supabase", health_url: "https://a.vercel.app"), "url").first
    assert_equal "Rails", check_badge(Client.new(kind: "rails", health_url: "https://x.com/up"), "url").first
    assert_equal "Cloudflare Workers", check_badge(Client.new(kind: "other", health_url: "https://h.x.workers.dev/health"), "url").first
    assert_equal "URL", check_badge(Client.new(kind: "other", health_url: "https://x.com"), "url").first
    assert_equal "Supabase", check_badge(Client.new, "supabase").first
  end
end
