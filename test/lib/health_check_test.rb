require "test_helper"

class HealthCheckTest < ActiveSupport::TestCase
  def response(code, body = "", error: nil)
    HealthCheck::Response.new(code:, body:, ms: 20, error:)
  end

  test "URL 체크는 2xx만 정상이고 JSON의 failed[]를 사유에 싣는다" do
    stubbing(HealthCheck, :get, response(503, '{"ok":false,"failed":["db","disk"]}')) do
      result = HealthCheck::Url.call("https://x.example.com/health")
      assert_not result.ok
      assert_equal "HTTP 503 — db, disk", result.error
      assert_equal 503, result.status_code
    end

    stubbing(HealthCheck, :get, response(200, "<html>")) do
      assert HealthCheck::Url.call("https://x.example.com/").ok
    end
  end

  test "네트워크 오류는 원인이 사유에 남는다" do
    stubbing(HealthCheck, :get, response(nil, nil, error: "SocketError: getaddrinfo")) do
      result = HealthCheck::Url.call("https://nowhere.example.com/")
      assert_not result.ok
      assert_equal "SocketError: getaddrinfo", result.error
    end
  end

  test "Supabase는 401이 정상, 540(정지)은 실패" do
    stubbing(HealthCheck, :get, response(401)) { assert HealthCheck::Supabase.call("abc").ok }
    stubbing(HealthCheck, :get, response(540)) do
      result = HealthCheck::Supabase.call("abc")
      assert_not result.ok
      assert_equal "Supabase HTTP 540", result.error
    end
  end

  test "Vercel은 토큰이 없으면 실패, 최신 배포가 ERROR면 실패, BUILDING이면 정상" do
    ENV["VERCEL_TOKEN"] = ""
    assert_equal "VERCEL_TOKEN 미설정", HealthCheck::Vercel.call("prj_x").error

    ENV["VERCEL_TOKEN"] = "t"
    stubbing(HealthCheck, :get, response(200, '{"deployments":[{"readyState":"ERROR"}]}')) do
      assert_equal "배포 상태: ERROR", HealthCheck::Vercel.call("prj_x").error
    end
    stubbing(HealthCheck, :get, response(200, '{"deployments":[{"readyState":"BUILDING"}]}')) do
      assert HealthCheck::Vercel.call("prj_x", "team_y").ok
    end
    stubbing(HealthCheck, :get, response(200, '{"deployments":[]}')) do
      assert_equal "배포 내역 없음", HealthCheck::Vercel.call("prj_x").error
    end
    stubbing(HealthCheck, :get, response(502, "")) do
      assert_equal "Vercel API 502", HealthCheck::Vercel.call("prj_x").error
    end
  ensure
    ENV.delete("VERCEL_TOKEN")
  end

  FakeHttp = Struct.new(:code, :body, :location) do
    def [](name) = name.to_s.casecmp?("location") ? location : nil
  end

  test "get은 리다이렉트를 따라가 마지막 응답을 돌려준다" do
    hops = [ FakeHttp.new("307", "", "/login"), FakeHttp.new("200", "<html>", nil) ]
    seen = []
    stubbing(HealthCheck, :request, ->(uri, _headers) { seen << uri.to_s; hops.shift }) do
      result = HealthCheck.get("https://x.example.com/")
      assert_equal 200, result.code
      assert_nil result.error
    end
    assert_equal [ "https://x.example.com/", "https://x.example.com/login" ], seen
  end

  test "get은 리다이렉트를 3번까지만 따라간다" do
    loop_hop = FakeHttp.new("302", "", "https://x.example.com/again")
    stubbing(HealthCheck, :request, ->(*) { loop_hop }) do
      assert_equal 302, HealthCheck.get("https://x.example.com/").code
    end
  end

  test "run은 실패하면 한 번 더 본다" do
    calls = 0
    results = [ HealthCheck::Result.new(ok: false, status_code: 500, ms: 1, error: "HTTP 500"),
                HealthCheck::Result.new(ok: true, status_code: 200, ms: 1, error: nil) ]
    stubbing(HealthCheck, :call, ->(*) { results[(calls += 1) - 1] }) do
      assert HealthCheck.run(clients(:acme), "url", retry_delay: 0).ok
    end
    assert_equal 2, calls
  end
end
