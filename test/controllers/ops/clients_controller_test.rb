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
