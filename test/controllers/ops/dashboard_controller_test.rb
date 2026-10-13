require "test_helper"

class Ops::DashboardControllerTest < ActionDispatch::IntegrationTest
  setup { host! "ops.example.com" }

  test "로그인 없이는 로그인 화면으로 보낸다" do
    get "/"
    assert_redirected_to "/session/new"
  end

  test "로그인하면 계약현황과 서비스 상태가 보인다" do
    sign_in_as users(:one)
    clients(:acme).health_logs.create!(check_type: "url", ok: false, error: "HTTP 503 — db", ms: 42, checked_at: Time.current)

    get "/"

    assert_response :success
    assert_match "1,000,000원", response.body          # 미수금 = acme_balance
    assert_match "에이스상사", response.body             # 감시 서비스
    assert_match "HTTP 503 — db", response.body
    assert_select "section h2", text: "미수금"
    assert_match "올해 수금", response.body
  end

  test "ops 서브도메인이 아니면 공개 사이트가 나온다" do
    host! "www.example.com"
    get "/"
    assert_response :success
    assert_no_match "미수금", response.body
  end
end
