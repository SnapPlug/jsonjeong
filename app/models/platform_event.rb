# 우리가 쓰는 플랫폼의 장애·릴리스 소식. PlatformWatchJob이 한 시간마다 채운다.
class PlatformEvent < ApplicationRecord
  SOURCES = { "vercel" => "Vercel", "supabase" => "Supabase", "cloudflare" => "Cloudflare", "rails" => "Rails", "nextjs" => "Next.js" }.freeze

  DIRECTIONS = { "ne" => "northeast", "se" => "southeast" }.freeze
  REGION = /\b(us|eu|ap|ca|sa|me|af)[- ](northeast|southeast|north|south|east|west|central|ne|se)[- ]?(\d)\b/i

  validates :source, inclusion: { in: SOURCES.keys }
  validates :kind, inclusion: { in: %w[incident release] }

  scope :recent, -> { order(happened_at: :desc) }

  def resolved? = status == "resolved"
  def label = SOURCES[source]

  # 제목에 적힌 AWS 리전 코드. us-east-1 · ap-ne1 · EU West 1 형식을 읽는다.
  # ponytail: "EU region"·"Eastern US" 같은 말은 안 읽는다. 빈 배열이면 호출 쪽이 전부 영향 후보로 둔다(놓치는 것보다 낫다).
  def regions
    title.to_s.scan(REGION).map do |area, direction, number|
      "#{area.downcase}-#{DIRECTIONS.fetch(direction.downcase, direction.downcase)}-#{number}"
    end
  end
end
