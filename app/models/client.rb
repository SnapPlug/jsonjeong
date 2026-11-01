# 고객사. 돈(계약·납부)의 단위이자, 서비스 정보가 있으면 감시의 단위.
class Client < ApplicationRecord
  KINDS = %w[vercel_supabase channeltalk rails other].freeze

  has_many :contracts, dependent: :destroy
  has_many :payments, through: :contracts
  has_many :health_logs, dependent: :destroy

  enum :status, %w[active paused completed].index_by(&:itself), default: "active"

  normalizes :name, :health_url, :vercel_project_id, :vercel_team_id, :supabase_ref, :stack_version,
             with: ->(value) { value.strip.presence }

  validates :name, presence: true, uniqueness: true
  validates :kind, inclusion: { in: KINDS }

  # 감시 대상: 일시중지가 아니고 체크할 정보가 하나라도 있는 고객사
  scope :monitored, -> {
    where.not(status: "paused")
      .where("health_url IS NOT NULL OR vercel_project_id IS NOT NULL OR supabase_ref IS NOT NULL")
  }

  # 플랫폼 소식(PlatformEvent.source)이 닿는 고객사. 일시중지는 뺀다.
  # vercel/supabase는 감시 정보로, cloudflare는 Workers 주소로, rails/nextjs는 종류로 판단한다.
  def self.affected_by(source)
    base = where.not(status: "paused")
    case source
    when "vercel" then base.where.not(vercel_project_id: nil)
    when "supabase" then base.where.not(supabase_ref: nil)
    when "cloudflare" then base.where("health_url LIKE ?", "%workers.dev%")
    when "rails" then base.where(kind: "rails")
    when "nextjs" then base.where(kind: "vercel_supabase")
    else none
    end
  end

  # 릴리스 알림 한 줄: "더온실 15.5.18 ⚠️". 같은 줄기(메이저)에서 릴리스보다 낮으면 ⚠️, 같거나 높으면 ✅.
  # 줄기 규칙(2026-11-02 Jason): 바로 전 메이저까지는 둔다. 두 메이저 뒤처지면 보안 지원이 끝나니 ⬆️ 줄기 올릴 때. 버전 모르면 ?.
  def version_mark(release_tag)
    return "#{name} ?" unless stack_version
    mine, theirs = Gem::Version.new(stack_version), Gem::Version.new(release_tag.delete_prefix("v"))
    gap = theirs.segments.first - mine.segments.first
    return "#{name} #{stack_version} ⬆️ 줄기 올릴 때" if gap >= 2   # 두 메이저 뒤처짐 = 보안 지원 끝 → 올릴 계획
    return "#{name} #{stack_version}" if gap == 1                   # 바로 전 메이저 = 아직 지원됨, 둔다
    "#{name} #{stack_version} #{mine < theirs ? '⚠️' : '✅'}"
  rescue ArgumentError
    "#{name} #{stack_version}"
  end

  # 이 고객사에 적용되는 체크 종류 (HealthLog::CHECK_TYPES 중)
  def checks
    [ ("url" if health_url), ("vercel" if vercel_project_id), ("supabase" if supabase_ref) ].compact
  end
end
