# 복사 위치: app/models/concerns/portone_payable.rb
# User 모델에 include PortonePayable 추가

module PortonePayable
  extend ActiveSupport::Concern

  included do
    has_many :portone_payments
    scope :paid_users, -> { where.not(portone_paid_at: nil) }
  end

  def paid?
    portone_paid_at.present?
  end

  def activate_portone!(payment_id:, amount:, channel: nil)
    portone_payments.create!(
      payment_id: payment_id,
      status:     "paid",
      amount:     amount,
      channel:    channel
    )
    update!(portone_paid_at: Time.current, portone_payment_id: payment_id)
  end

  def deactivate_portone!
    update!(portone_paid_at: nil)
    portone_payments.where(payment_id: portone_payment_id).update_all(status: "cancelled")
  end

  # 웹훅의 paymentId로 유저 찾기
  def self.find_by_portone_payment(payment_id)
    PortonePayment.find_by(payment_id: payment_id)&.user
  end
end
