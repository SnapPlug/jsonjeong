module HealthCheck
  # 최신 프로덕션 배포가 ERROR면 실패. BUILDING·QUEUED는 이전 배포가 계속 서비스 중이라 정상.
  module Vercel
    def self.call(project_id, team_id = nil)
      token = ENV["VERCEL_TOKEN"].to_s.strip
      return Result.new(ok: false, status_code: nil, ms: nil, error: "VERCEL_TOKEN 미설정") if token.empty?

      # 고객사 계정의 프로젝트는 teamId가 있어야 보인다.
      url = "https://api.vercel.com/v6/deployments?projectId=#{project_id}&limit=1&target=production"
      url += "&teamId=#{team_id}" if team_id.present?
      response = HealthCheck.get(url, "Authorization" => "Bearer #{token}")
      return HealthCheck.failure(response) if response.error
      return HealthCheck.failure(response, "Vercel API #{response.code}") unless response.code == 200

      deployment = JSON.parse(response.body)["deployments"]&.first
      return HealthCheck.failure(response, "배포 내역 없음") unless deployment

      ok = deployment["readyState"] != "ERROR"
      Result.new(ok:, status_code: response.code, ms: response.ms, error: ok ? nil : "배포 상태: ERROR")
    end
  end
end
