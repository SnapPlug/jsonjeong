require "test_helper"

class SecurityAuditTest < ActiveSupport::TestCase
  def page(code, type: "text/html", headers: {}, body: "")
    HealthCheck::Response.new(code:, body:, ms: 1, error: nil, headers: { "content-type" => [ type ] }.merge(headers))
  end

  test "웹: 프레임 차단·HSTS 없는 HTML, secure 없는 쿠키, 열린 /.env를 잡는다" do
    responses = {
      "https://a.example.com/" => page(200, headers: { "set-cookie" => [ "_s=1; path=/; httponly", "_t=2; path=/; secure" ] }),
      "https://a.example.com/.env" => page(200, type: "text/plain", body: "SECRET=1"),
      "https://a.example.com/.git/config" => page(404)
    }
    stubbing(HealthCheck, :get, ->(url, *) { responses.fetch(url) }) do
      issues = SecurityAudit.web("A", "https://a.example.com")
      assert_equal [ "A: 프레임 차단 헤더 없음", "A: HSTS 없음", "A: secure 없는 쿠키 _s", "A: /.env 열림" ], issues
    end
  end

  test "웹: 헤더가 갖춰졌고 /.env가 HTML 첫 화면으로 풀리면 문제 없음. HTML이 아니면 헤더는 보지 않는다" do
    ok = page(200, headers: { "x-frame-options" => [ "DENY" ], "strict-transport-security" => [ "max-age=1" ] })
    stubbing(HealthCheck, :get, ok) { assert_empty SecurityAudit.web("A", "https://a.example.com") }
    stubbing(HealthCheck, :get, page(404, type: "application/json")) { assert_empty SecurityAudit.web("W", "https://w.example.com") }
  end

  test "DB: 노출된 칸을 한 줄씩 알리고, 토큰이 없으면 건너뛴다고 말한다" do
    ENV["SUPABASE_ACCESS_TOKEN"] = "t"
    rows = HealthCheck::Response.new(code: 201, body: '[{"table_name":"partners","columns":"email, business_number"}]', ms: 0, error: nil)
    stubbing(SecurityAudit, :supabase_query, rows) do
      assert_equal [ "D: 공개 키로 partners의 email, business_number 읽힘" ], SecurityAudit.database("D", "ref")
    end
    public_only = HealthCheck::Response.new(code: 201, body: '[{"table_name":"partners","columns":"phone"}]', ms: 0, error: nil)
    stubbing(SecurityAudit, :supabase_query, public_only) do
      assert_empty SecurityAudit.database("더온실", "fspjpbbvunuabibaomfh") # 일부러 공개하는 칸은 알리지 않는다
    end
    stubbing(SecurityAudit, :supabase_query, HealthCheck::Response.new(code: 403, body: "", ms: 0, error: nil)) do
      assert_equal [ "D: Supabase 확인 못 함 (토큰 계정 밖 프로젝트)" ], SecurityAudit.database("D", "ref")
    end

    ENV["SUPABASE_ACCESS_TOKEN"] = ""
    assert_equal [ "D: Supabase 점검 건너뜀 (SUPABASE_ACCESS_TOKEN 미설정)" ], SecurityAudit.database("D", "ref")
  end

  test "서버: 상태 줄을 문제로 바꾸고, 키가 없으면 그렇게 알린다" do
    assert_equal [ "서버 S: 재부팅 대기 (보안 업데이트 미적용)", "서버 S: SSH 비밀번호 로그인 켜짐" ],
                 SecurityAudit.server_issues("S", "reboot=yes\npassword=yes\n")
    assert_empty SecurityAudit.server_issues("S", "reboot=no\npassword=no\n")

    ENV["OPS_AUDIT_SSH_KEY"] = ""
    assert_equal [ "서버 S: 점검 키 미설정" ], SecurityAudit.server("1.2.3.4", "S")
  end
end
