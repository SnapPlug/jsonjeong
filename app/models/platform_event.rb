# 우리가 쓰는 플랫폼의 장애·릴리스 소식. PlatformWatchJob이 한 시간마다 채운다.
class PlatformEvent < ApplicationRecord
  SOURCES = { "vercel" => "Vercel", "supabase" => "Supabase", "cloudflare" => "Cloudflare", "rails" => "Rails", "nextjs" => "Next.js" }.freeze

  validates :source, inclusion: { in: SOURCES.keys }
  validates :kind, inclusion: { in: %w[incident release] }

  scope :recent, -> { order(happened_at: :desc) }

  def resolved? = status == "resolved"
  def label = SOURCES[source]
end
