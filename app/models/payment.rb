class Payment < ApplicationRecord
  belongs_to :contract

  enum :kind, %w[deposit interim balance].index_by(&:itself)
  enum :status, %w[pending paid overdue cancelled].index_by(&:itself), default: "pending"

  validates :amount, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :due_on, presence: true

  before_save { self.paid_on ||= Date.current if paid? }

  scope :unpaid, -> { where(status: %w[pending overdue]).order(:due_on) }

  def self.mark_overdue!
    pending.where(due_on: ...Date.current).update_all(status: "overdue")
  end

  # 마감일(due_on) 기준 월별 수금 합계. { "2026-09" => 1000000, ... }
  def self.monthly_paid(months: 12)
    from = (Date.current << (months - 1)).beginning_of_month
    paid.where(due_on: from..).group("strftime('%Y-%m', due_on)").sum(:amount)
  end
end
