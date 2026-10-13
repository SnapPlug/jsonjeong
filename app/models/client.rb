# 고객사. 돈(계약·납부)의 단위이자, 서비스 정보가 있으면 감시의 단위.
class Client < ApplicationRecord
  KINDS = %w[vercel_supabase channeltalk rails other].freeze

  has_many :contracts, dependent: :destroy
  has_many :payments, through: :contracts
  has_many :health_logs, dependent: :destroy

  enum :status, %w[active paused completed].index_by(&:itself), default: "active"

  normalizes :name, :health_url, :vercel_project_id, :vercel_team_id, :supabase_ref,
             with: ->(value) { value.strip.presence }

  validates :name, presence: true, uniqueness: true
  validates :kind, inclusion: { in: KINDS }

  # 감시 대상: 일시중지가 아니고 체크할 정보가 하나라도 있는 고객사
  scope :monitored, -> {
    where.not(status: "paused")
      .where("health_url IS NOT NULL OR vercel_project_id IS NOT NULL OR supabase_ref IS NOT NULL")
  }

  # 이 고객사에 적용되는 체크 종류 (HealthLog::CHECK_TYPES 중)
  def checks
    [ ("url" if health_url), ("vercel" if vercel_project_id), ("supabase" if supabase_ref) ].compact
  end
end
