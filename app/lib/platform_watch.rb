require "json"

# 플랫폼 소식 읽기. 장애는 Statuspage 공통 API(Vercel·Supabase·Cloudflare), 릴리스는 GitHub(Rails·Next.js).
# 릴리스 규칙(A안): 보안 릴리스와 메이저·마이너만. 패치·canary·beta·rc는 거르되 보안이면 알린다.
module PlatformWatch
  Event = Data.define(:source, :kind, :external_id, :title, :status, :url, :happened_at)

  STATUS_PAGES = {
    "vercel" => "https://www.vercel-status.com",
    "supabase" => "https://status.supabase.com",
    "cloudflare" => "https://www.cloudflarestatus.com"
  }.freeze
  REPOS = { "rails" => "rails/rails", "nextjs" => "vercel/next.js" }.freeze
  SECURITY = /security|cve-\d/i

  def self.fetch_all
    STATUS_PAGES.flat_map { |source, base| incidents(source, base) } + REPOS.flat_map { |source, repo| releases(source, repo) }
  end

  def self.incidents(source, base)
    body = fetch_json("#{base}/api/v2/incidents.json") or return []
    Array(body["incidents"]).map do |i|
      Event.new(source:, kind: "incident", external_id: i["id"], title: i["name"], status: i["status"],
                url: i["shortlink"] || "#{base}/incidents/#{i['id']}", happened_at: Time.zone.parse(i["created_at"]))
    end
  end

  def self.releases(source, repo)
    body = fetch_json("https://api.github.com/repos/#{repo}/releases?per_page=30") or return []
    Array(body).filter_map do |r|
      status = release_status(r, source:)
      next unless status
      Event.new(source:, kind: "release", external_id: r["tag_name"], title: r["tag_name"], status:,
                url: r["html_url"], happened_at: Time.zone.parse(r["published_at"]))
    end
  end

  # 우리가 돌리는 Rails 줄기(예: "8.1"). 이 줄기의 보안 릴리스만 알린다 — 7.2·8.0 보안 공지는 우리와 상관없다.
  OUR_RAILS = "#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}".freeze

  # "security" | "minor" | nil(알리지 않음). Rails 보안 릴리스는 x.y.z.w 네 자리거나 본문에 security/CVE.
  # 새 마이너(x.y.0)는 어느 줄기든 알린다 — 버전이 바뀌는 건 알아야 한다.
  def self.release_status(release, source: nil)
    tag = release["tag_name"].to_s
    return nil if release["prerelease"] || tag.match?(/canary|beta|rc|alpha/i)
    numbers = tag.delete_prefix("v").split(".")
    return "minor" if numbers[2].to_i == 0 && numbers.size == 3
    return nil if source == "rails" && !tag.start_with?("v#{OUR_RAILS}.")
    "security" if numbers.size >= 4 || release["body"].to_s.match?(SECURITY)
  end

  def self.fetch_json(url)
    response = HealthCheck.get(url, { "User-Agent" => "ops.jsonjeong.com", "Accept" => "application/json" })
    if response.error || response.code != 200
      Rails.logger.warn("[platform_watch] #{url} 실패: #{response.error || response.code}")
      return nil
    end
    JSON.parse(response.body)
  rescue JSON::ParserError => e
    Rails.logger.warn("[platform_watch] #{url} JSON 오류: #{e.message}")
    nil
  end
end
