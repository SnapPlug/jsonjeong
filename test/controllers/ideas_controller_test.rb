require "test_helper"

class IdeasControllerTest < ActionDispatch::IntegrationTest
  test "korean archive at root" do
    get "/"
    assert_response :success
    assert_match '<html lang="ko">', response.body
    assert_match "작업 시간", response.body
    assert_match "workoutbell.com", response.body
    assert_match 'hreflang="en"', response.body
    assert_match '"@type":"Person"', response.body
    assert_match '"@type":"ItemList"', response.body
  end

  test "english archive at /en" do
    get "/en"
    assert_response :success
    assert_match '<html lang="en">', response.body
    assert_match "Hours", response.body
    assert_match 'href="/en/ideas/workoutbell"', response.body
    assert_match "Ideas", response.body
  end

  test "retro page in both languages" do
    get "/ideas/workoutbell"
    assert_response :success
    assert_match '<html lang="ko">', response.body
    assert_match '"@type":"Article"', response.body
    get "/en/ideas/workoutbell"
    assert_response :success
    assert_match '<html lang="en">', response.body
  end

  test "unknown idea is 404, idea without retro still has a page" do
    get "/ideas/nope"
    assert_response :not_found
    get "/ideas/block-game"
    assert_response :success
    assert_match "막힌 곳", response.body
  end

  test "archive h1 names the page, not the person" do
    get "/"
    assert_select "h1", count: 1, text: "아이디어 아카이브"
    get "/en"
    assert_select "h1", count: 1, text: "Idea archive"
  end

  test "idea page title and description carry the numbers" do
    get "/ideas/workoutbell"
    assert_select "title", text: /\Aworkoutbell\.com · 3\.6시간 검증 기록 — /
    assert_select "meta[name=description][content*=?]", "3.6시간 동안 $10.44 쓰고"
    get "/en/ideas/workoutbell"
    assert_select "title", text: /\Aworkoutbell\.com · 3\.6h of validation — /
    assert_select "meta[name=description][content*=?]", "3.6h of work, $10.44 spent"
  end

  test "article structured data has dates and image" do
    get "/ideas/workoutbell"
    article = css_select('script[type="application/ld+json"]').map { JSON.parse(_1.text) }.find { _1["@type"] == "Article" }
    assert_equal "2026-10-03", article["datePublished"]
    assert article["dateModified"].present?
    assert_match %r{/assets/ideas/workoutbell-.*\.jpg\z}, article["image"]
  end
end
