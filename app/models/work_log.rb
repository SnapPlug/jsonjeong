# 고객사별 유지보수 작업 시간. 유상 유지보수 단가를 추정이 아니라 실측으로 정하려고 쌓는다 (2026-11-13).
class WorkLog < ApplicationRecord
  KINDS = { "triage" => "공지 확인", "security" => "보안 패치", "server" => "서버 관리", "support" => "운영 지원", "other" => "기타" }.freeze

  belongs_to :client

  normalizes :note, with: ->(value) { value.strip.presence }

  validates :worked_on, presence: true
  validates :minutes, numericality: { only_integer: true, greater_than: 0 }
  validates :kind, inclusion: { in: KINDS.keys }

  # 최근 n달의 달별 합계(분). 기록 없는 달도 0으로 채운다: { "2026-11" => 90, … } (오래된 순)
  def self.monthly_minutes(months: 6, today: Date.current)
    keys = (0...months).map { |i| (today << i).strftime("%Y-%m") }.reverse
    sums = where(worked_on: (today << (months - 1)).beginning_of_month..).group("strftime('%Y-%m', worked_on)").sum(:minutes)
    keys.index_with { |key| sums.fetch(key, 0) }
  end
end
