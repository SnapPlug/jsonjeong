require "test_helper"

class SeoControllerTest < ActionDispatch::IntegrationTest
  test "robots.txt is served as plain text and welcomes AI crawlers" do
    get "/robots.txt"
    assert_response :success
    assert_equal "text/plain", response.media_type
    assert_match "GPTBot", response.body
    assert_match "ClaudeBot", response.body
    assert_match "PerplexityBot", response.body
    assert_match "Sitemap: https://jsonjeong.com/sitemap.xml", response.body
  end

  test "robots.txt uses a short cache, not the 1-year asset cache" do
    get "/robots.txt"
    assert_match "max-age=3600", response.headers["Cache-Control"].to_s
  end

  test "sitemap.xml is valid xml with a lastmod" do
    get "/sitemap.xml"
    assert_response :success
    assert_equal "application/xml", response.media_type
    assert_match "<loc>https://jsonjeong.com/</loc>", response.body
    assert_match %r{<lastmod>\d{4}-\d{2}-\d{2}</lastmod>}, response.body
  end

  test "llms.txt is served for AI crawlers" do
    get "/llms.txt"
    assert_response :success
    assert_equal "text/plain", response.media_type
    assert_match "jsonjeong.com", response.body
    assert_match "SnapDeck", response.body
  end
end
