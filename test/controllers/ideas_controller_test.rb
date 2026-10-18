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

  test "unknown idea or idea without retro is 404" do
    get "/ideas/nope"
    assert_response :not_found
    get "/ideas/block-game"
    assert_response :not_found
  end
end
