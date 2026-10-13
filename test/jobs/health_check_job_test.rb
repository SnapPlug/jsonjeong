require "test_helper"

class HealthCheckJobTest < ActiveJob::TestCase
  FAIL = HealthCheck::Result.new(ok: false, status_code: 503, ms: 12, error: "HTTP 503 — db")
  PASS = HealthCheck::Result.new(ok: true, status_code: 200, ms: 8, error: nil)

  test "첫 실패는 기록만 하고 알리지 않는다" do
    messages = run_job(FAIL)

    assert_equal 2, clients(:acme).health_logs.count   # url + vercel
    assert_empty messages
  end

  test "연속 2회째 실패에 체크마다 한 통씩 알린다" do
    clients(:acme).checks.each { |c| clients(:acme).health_logs.create!(check_type: c, ok: false, checked_at: 5.minutes.ago) }

    messages = run_job(FAIL)

    assert_equal [ "🔴 에이스상사 · URL\nHTTP 503 — db", "🔴 에이스상사 · Vercel\nHTTP 503 — db" ], messages
  end

  test "2회 이상 실패 뒤 정상이면 복구를 알린다" do
    [ 10, 5 ].each { |m| clients(:acme).health_logs.create!(check_type: "url", ok: false, checked_at: m.minutes.ago) }
    clients(:acme).health_logs.create!(check_type: "vercel", ok: true, checked_at: 5.minutes.ago)

    messages = run_job(PASS)

    assert_equal [ "🟢 에이스상사 · URL 복구" ], messages
  end

  test "감시 대상이 아닌 고객사는 건드리지 않고 끝에 하트비트를 보낸다" do
    beats = 0
    stubbing(HealthCheck, :heartbeat, -> { beats += 1 }) do
      stubbing(HealthCheck, :run, PASS) { HealthCheckJob.perform_now }
    end

    assert_equal 0, clients(:channel_only).health_logs.count
    assert_equal 1, beats
  end

  private
    def run_job(result)
      messages = []
      stubbing(HealthCheck, :heartbeat, nil) do
        stubbing(HealthCheck, :run, result) do
          stubbing(Telegram, :send_message, ->(text) { messages << text; Telegram::Result.new(true, nil) }) do
            HealthCheckJob.perform_now
          end
        end
      end
      messages
    end
end
