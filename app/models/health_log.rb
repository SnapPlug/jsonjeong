class HealthLog < ApplicationRecord
  CHECK_TYPES = %w[url vercel supabase].freeze
  LABELS = { "url" => "URL", "vercel" => "Vercel", "supabase" => "Supabase" }.freeze

  belongs_to :client

  validates :check_type, inclusion: { in: CHECK_TYPES }

  # 체크(고객사 × 종류)마다 가장 최근 1건. id가 시간순이라 MAX(id)로 충분하다.
  scope :latest, -> { where(id: HealthLog.group(:client_id, :check_type).select("MAX(id)")) }

  # 알림 판정. previous = 같은 체크의 직전 결과 2개(오래된 순), ok = 이번 결과.
  #   :down — 연속 2회째 실패에만. 3회째부터는 같은 장애라 조용히.
  #   :up   — 2회 이상 실패(알린 적 있음) 뒤 첫 정상에만. 단발 실패 뒤 회복은 알리지 않는다.
  # 옛 Overload의 alert-rule.ts를 그대로 옮긴 규칙. 8월에 오탐을 세 번 고쳐 정한 자리라 바꾸지 않는다.
  def self.transition(previous, ok)
    prev1, prev2 = previous[-1], previous[-2]
    if ok
      :up if prev1 == false && prev2 == false
    elsif prev1 == false && prev2 != false
      :down
    end
  end

  def self.purge!(older_than: 30.days)
    where(checked_at: ...older_than.ago).delete_all
  end
end
