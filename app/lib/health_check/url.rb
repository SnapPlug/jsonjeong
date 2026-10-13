module HealthCheck
  # 2xx면 정상. 대상이 /health 처럼 죽은 항목을 JSON(failed)으로 알려주면 알림에 함께 싣는다.
  module Url
    def self.call(url)
      response = HealthCheck.get(url)
      return HealthCheck.failure(response) if response.error

      ok = (200..299).cover?(response.code)
      Result.new(ok:, status_code: response.code, ms: response.ms,
                 error: ok ? nil : "HTTP #{response.code}#{failed_items(response.body)}")
    end

    def self.failed_items(body)
      failed = JSON.parse(body.to_s)["failed"]
      failed.is_a?(Array) && failed.any? ? " — #{failed.join(', ')}" : ""
    rescue JSON::ParserError, TypeError
      ""
    end
  end
end
