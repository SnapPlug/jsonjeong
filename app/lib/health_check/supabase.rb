module HealthCheck
  # REST 루트를 가짜 키로 찌른다. 401이 오면 게이트웨이가 살아 있는 것이고, 무료 플랜 정지면 540이 온다.
  # (고객사 Supabase 로그에 5분마다 401 GET이 찍히는 건 이 체크다.)
  module Supabase
    def self.call(ref)
      response = HealthCheck.get("https://#{ref}.supabase.co/rest/v1/", "apikey" => "placeholder")
      return HealthCheck.failure(response) if response.error

      ok = response.code == 401 || (200..299).cover?(response.code)
      Result.new(ok:, status_code: response.code, ms: response.ms, error: ok ? nil : "Supabase HTTP #{response.code}")
    end
  end
end
