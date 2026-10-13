require "net/http"
require "json"

# 고객사 서비스 생존 확인. 세 가지 체크 전부 HTTP 한 번이고, 실패하면 2초 뒤 한 번 더 본다.
# 결과는 HealthLog 한 줄로 남고, 알릴지는 HealthLog.transition이 정한다.
module HealthCheck
  Result = Data.define(:ok, :status_code, :ms, :error)
  Response = Data.define(:code, :body, :ms, :error)
  TIMEOUT = 10

  def self.run(client, check_type, retry_delay: 2)
    result = call(client, check_type)
    return result if result.ok
    sleep retry_delay
    call(client, check_type)
  end

  def self.call(client, check_type)
    case check_type
    when "url" then Url.call(client.health_url)
    when "vercel" then Vercel.call(client.vercel_project_id, client.vercel_team_id)
    when "supabase" then Supabase.call(client.supabase_ref)
    else raise ArgumentError, "알 수 없는 체크: #{check_type}"
    end
  end

  # 감시자 자신의 생존 신호 (Healthchecks.io). 한 바퀴 다 돌았을 때만 보내서, 끊기면 그쪽이 텔레그램으로 알린다.
  def self.heartbeat
    url = ENV["HEALTHCHECKS_URL"].to_s.strip
    return if url.empty?
    Net::HTTP.get_response(URI(url))
  rescue => e
    Rails.logger.warn("[health_check] heartbeat 실패: #{e.class} #{e.message}")
  end

  # GET 한 번. 네트워크 오류는 예외 대신 error에 담아 돌려준다 — 원인(ENOTFOUND, 타임아웃…)이 로그에 남아야 한다.
  def self.get(url, headers = {})
    uri = URI(url)
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                               open_timeout: TIMEOUT, read_timeout: TIMEOUT) do |http|
      http.get(uri.request_uri, headers)
    end
    Response.new(code: response.code.to_i, body: response.body, ms: elapsed(started), error: nil)
  rescue => e
    Response.new(code: nil, body: nil, ms: elapsed(started), error: "#{e.class}: #{e.message}")
  end

  def self.elapsed(started)
    ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round
  end

  def self.failure(response, message = response.error)
    Result.new(ok: false, status_code: response.code, ms: response.ms, error: message)
  end
end
