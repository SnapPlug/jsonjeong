# 우리가 쓰는 플랫폼의 장애·릴리스 소식. PlatformWatchJob이 한 시간마다 채운다.
class PlatformEvent < ApplicationRecord
  SOURCES = { "vercel" => "Vercel", "supabase" => "Supabase", "cloudflare" => "Cloudflare", "rails" => "Rails", "nextjs" => "Next.js" }.freeze

  DIRECTIONS = { "ne" => "northeast", "se" => "southeast" }.freeze
  REGION = /\b(us|eu|ap|ca|sa|me|af)[- ](northeast|southeast|north|south|east|west|central|ne|se)[- ]?(\d)\b/i

  # 장애 알림 기준: 고객사가 실제로 쓰는 기능이 멈출 때만. 대시보드·로그·빌드·다른 지역은 저장만 한다.
  # ponytail: 제목 낱말로 고른다. 놓친 장애가 서비스를 멈추면 5분 헬스체크가 알린다.
  # 쓰는 기능이 바뀌면 여기를 고친다(2026-11-03 기준: Supabase DB·인증·Storage, Vercel 함수·CDN, Workers·D1·R2).
  USED = {
    "supabase" => /database|connection|pooler|supavisor|storage|\bauth\b|outage/i,
    "vercel" => /functions?\b|\bcdn\b|\bedge\b|\b5\d\d\b|\b404\b|routing|outage/i,
    "cloudflare" => /\bworkers?\b|\bd1\b|\br2\b/i
  }.freeze
  NOT_SERVING = {
    "supabase" => /restored|upgrade/i,
    "vercel" => /\bauth\b/i,
    "cloudflare" => /build|deploy|\bapi\b|cron|enam|wnam|eeur|weur|europe|north america/i
  }.freeze
  # Vercel 함수 리전. iad1은 기본값(더온실·사이·슬립·정든), icn1은 snapplug_app·사이. 2026-11-03 Vercel API로 확인.
  OUR_VERCEL_REGIONS = %w[iad1 icn1].freeze

  validates :source, inclusion: { in: SOURCES.keys }
  validates :kind, inclusion: { in: %w[incident release] }

  scope :recent, -> { order(happened_at: :desc) }

  def resolved? = status == "resolved"
  def label = SOURCES[source]

  def touches_us?
    return false unless title.to_s.match?(USED.fetch(source)) && !title.to_s.match?(NOT_SERVING.fetch(source))
    return true unless source == "vercel"
    codes = title.downcase.scan(/\b[a-z]{3}\d\b/)
    codes.empty? || codes.intersect?(OUR_VERCEL_REGIONS)
  end

  # 제목에 적힌 AWS 리전 코드. us-east-1 · ap-ne1 · EU West 1 형식을 읽는다.
  # ponytail: "EU region"·"Eastern US" 같은 말은 안 읽는다. 빈 배열이면 호출 쪽이 전부 영향 후보로 둔다(놓치는 것보다 낫다).
  def regions
    title.to_s.scan(REGION).map do |area, direction, number|
      "#{area.downcase}-#{DIRECTIONS.fetch(direction.downcase, direction.downcase)}-#{number}"
    end
  end
end
