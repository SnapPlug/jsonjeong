# 복사 위치: app/models/concerns/polar_subscribable.rb
# User 모델에 include PolarSubscribable 추가

module PolarSubscribable
  extend ActiveSupport::Concern

  included do
    scope :active_subscribers, -> { where(polar_status: "active") }
  end

  def subscriber?
    polar_status == "active" &&
      (polar_access_until.nil? || polar_access_until.future?)
  end

  def activate_polar!(subscription_id:, access_until: nil)
    update!(
      polar_subscription_id: subscription_id,
      polar_status:          "active",
      polar_access_until:    access_until
    )
  end

  def cancel_polar!(access_until: nil)
    # ponytail: access_until 있으면 기간 종료 후 취소 (canceling), 없으면 즉시
    update!(
      polar_status:       access_until ? "canceling" : "canceled",
      polar_access_until: access_until
    )
  end
end
