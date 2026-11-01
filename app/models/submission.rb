# 다른 사람이 올린 실패 사례. 승인(approved)된 것만 공개 목록과 비교 기준에 들어간다.
class Submission < ApplicationRecord
  STATUSES = %w[pending approved rejected].freeze
  METRICS = %i[hours days cost_usd revenue_usd].freeze
  HTTPS = %r{\Ahttps://\S+\z}

  has_secure_token
  normalizes :email, with: ->(e) { e.to_s.strip.downcase }
  normalizes :url, :proof_url, with: ->(u) { u.to_s.strip.presence }

  validates :name, presence: true, length: { maximum: 80 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :status, inclusion: { in: STATUSES }
  validates :locale, inclusion: { in: %w[ko en] }
  validates :started_on, presence: true
  validates :hours, :cost_usd, :revenue_usd, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :stuck, :quit_signal, presence: true, length: { maximum: 300 }
  validates :tools, length: { maximum: 120 }
  validates :url, :proof_url, format: { with: HTTPS }, allow_nil: true
  validate :ended_after_started

  scope :approved, -> { where(status: "approved").order(created_at: :desc) }

  def approved? = status == "approved"
  def verified? = proof_url.present?
  def days = ((ended_on || Date.current) - started_on).to_i + 1

  # 아카이브(Jason 것 + 승인된 제출) 안에서 내 값이 몇 번째인지.
  # 돌려주는 값은 "내 값보다 작거나 같은 비율"(0–100). 시간·돈·기간은 낮을수록 덜 쓴 것이다.
  def percentile(metric)
    pool = self.class.pool.map { |row| row.public_send(metric).to_f }
    return nil if pool.empty?
    mine = public_send(metric).to_f
    (pool.count { |v| v <= mine } * 100.0 / pool.size).round
  end

  def self.pool = Idea.all + approved.to_a

  private

  def ended_after_started
    return if ended_on.nil? || started_on.nil? || ended_on >= started_on
    errors.add(:ended_on, :after_start)
  end
end
