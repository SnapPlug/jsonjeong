class Contract < ApplicationRecord
  belongs_to :client
  has_many :payments, dependent: :destroy

  enum :status, %w[in_progress completed overdue cancelled].index_by(&:itself), default: "in_progress"

  normalizes :name, :business_number, with: ->(value) { value.strip.presence }

  validates :name, :starts_on, :ends_on, presence: true
  validates :amount, numericality: { only_integer: true, greater_than: 0 }
  # 생성 때만 검사한다. 나중에 금액을 고쳐도 기존 납부 일정은 자동 조정되지 않는다.
  validate :payments_total_matches_amount, on: :create

  # 계약 기간에 맞춘 기본 납부 일정. 중도금 포함이면 30/40/30, 아니면 50/50.
  # 정수 나눗셈의 오차는 잔금에 몰아 합계를 계약 금액과 맞춘다.
  def build_default_payments(interim: false)
    ratios = interim ? { "deposit" => 30, "interim" => 40, "balance" => 30 } : { "deposit" => 50, "balance" => 50 }
    dates = { "deposit" => starts_on, "interim" => starts_on + (ends_on - starts_on) / 2, "balance" => ends_on }
    amounts = ratios.transform_values { |ratio| amount * ratio / 100 }
    amounts["balance"] = amount - amounts.except("balance").values.sum
    ratios.each_key { |kind| payments.build(kind:, amount: amounts[kind], due_on: dates[kind]) }
    payments
  end

  def self.mark_overdue!
    in_progress.where(ends_on: ...Date.current).update_all(status: "overdue")
  end

  private
    def payments_total_matches_amount
      return if payments.empty?
      total = payments.sum { |payment| payment.amount.to_i }
      errors.add(:payments, "합계(#{total})가 계약 금액(#{amount})과 다릅니다") if total != amount
    end
end
