require "test_helper"

class Ops::ClientsControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "ops.example.com"
    sign_in_as users(:one)
  end

  test "고객사 상세에 계약·납부·서비스 정보가 보인다" do
    get "/clients/#{clients(:acme).id}"
    assert_response :success
    assert_match "에이스 1차 구축", response.body
    assert_match "2,000,000원", response.body
    assert_select "input[name='client[health_url]'][value='https://acme.example.com/health']"
  end

  test "서비스 정보를 고친다" do
    patch "/clients/#{clients(:channel_only).id}", params: { client: { health_url: " https://channel.example.com/health ", kind: "rails" } }
    assert_redirected_to "/clients/#{clients(:channel_only).id}"
    assert_equal "https://channel.example.com/health", clients(:channel_only).reload.health_url
    assert_equal [ "url" ], clients(:channel_only).checks
  end

  test "작업 시간을 기록하면 고객사 화면에 달별 합계와 함께 보인다" do
    acme = clients(:acme)
    post "/clients/#{acme.id}/work_logs", params: { work_log: { worked_on: Date.current, minutes: 90, kind: "security", note: " Next.js 패치 " } }
    assert_redirected_to "/clients/#{acme.id}#work"
    assert_equal "Next.js 패치", acme.work_logs.last.note

    get "/clients/#{acme.id}"
    assert_match "1시간 30분", response.body
    assert_match "Next.js 패치", response.body

    post "/clients/#{acme.id}/work_logs", params: { work_log: { worked_on: Date.current, minutes: 0, kind: "security" } }
    assert_equal 1, acme.work_logs.count
  end

  test "납부 상태를 수금 완료로 바꾸면 수금일이 채워진다" do
    patch "/payments/#{payments(:acme_balance).id}", params: { payment: { status: "paid" } }
    assert_response :redirect
    assert_equal Date.current, payments(:acme_balance).reload.paid_on
  end

  test "지금 체크는 잡을 큐에 넣는다" do
    assert_enqueued_with(job: HealthCheckJob) do
      post "/health_check"
    end
    assert_redirected_to "/"
  end
end
