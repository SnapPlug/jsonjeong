require "test_helper"

class SubmissionsControllerTest < ActionDispatch::IntegrationTest
  VALID = { name: "빵집 챗봇", email: "x@y.co", started_on: "2026-10-01", ended_on: "2026-10-20",
            hours: 12, cost_usd: 30, revenue_usd: 0, stuck: "5초 제한", quit_signal: "20일째 결제 0" }.freeze

  test "form in both languages" do
    get "/submissions/new"
    assert_response :success
    assert_select "h1", "내 실패도 올리기"
    get "/en/submissions/new"
    assert_select "h1", "Add your failure"
  end

  test "create shows my position and is noindex" do
    assert_difference("Submission.count", 1) { post "/submissions", params: { submission: VALID } }
    follow_redirect!
    assert_response :success
    assert_match "빵집 챗봇", response.body
    assert_match "건과 나란히", response.body
    assert_select "meta[name=robots][content=noindex]"
    assert_match "미확인", response.body
  end

  test "invalid create re-renders with errors" do
    assert_no_difference("Submission.count") { post "/submissions", params: { submission: VALID.merge(hours: "") } }
    assert_response :unprocessable_content
    assert_match "들인 시간", response.body
  end

  test "honeypot drops bots silently" do
    assert_no_difference("Submission.count") { post "/submissions", params: { submission: VALID, website: "spam" } }
    assert_redirected_to "/"
  end

  test "archive lists approved submissions only, and the submit card" do
    Submission.create!(VALID.merge(status: "approved", name: "공개된 것"))
    Submission.create!(VALID.merge(name: "대기 중인 것"))
    get "/"
    assert_match "공개된 것", response.body
    assert_no_match "대기 중인 것", response.body
    assert_select "a[href='/submissions/new']"
  end

  test "unknown token is 404" do
    get "/submissions/nope"
    assert_response :not_found
  end
end
