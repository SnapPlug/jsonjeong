# 복사 위치: app/controllers/webhooks/polar_controller.rb
#
# 필수 준비:
#   1. Gemfile 에 gem "svix" 추가 후 bundle install
#   2. ENV["POLAR_WEBHOOK_SECRET"] 설정 (Polar 대시보드 → Webhooks)
#   3. config/routes.rb 에 라우트 추가 (routes_snippet.rb 참고)
#   4. bin/rails db:migrate (migration 파일 2개 먼저 적용)
#   5. on_* 메서드 서비스에 맞게 구현

class Webhooks::PolarController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :verify_signature
  before_action :skip_if_duplicate

  def receive
    event = JSON.parse(request.raw_post, symbolize_names: true)

    PolarEvent.create!(
      webhook_id: request.headers["webhook-id"],
      event_type: event[:type],
      payload:    event[:data]
    )

    dispatch(event)
    head :ok
  end

  private

  def verify_signature
    wh = Svix::Webhook.new(ENV.fetch("POLAR_WEBHOOK_SECRET"))
    wh.verify(request.raw_post, {
      "webhook-id"        => request.headers["webhook-id"],
      "webhook-timestamp" => request.headers["webhook-timestamp"],
      "webhook-signature" => request.headers["webhook-signature"]
    })
  rescue Svix::WebhookVerificationError
    head :unauthorized
  end

  # ponytail: Polar 는 실패 시 재시도 — 중복 처리 방지
  def skip_if_duplicate
    head :ok if PolarEvent.exists?(webhook_id: request.headers["webhook-id"])
  end

  def dispatch(event)
    case event[:type]
    when "order.created"          then on_order_created(event[:data])
    when "subscription.active"    then on_subscription_active(event[:data])
    when "subscription.canceled"  then on_subscription_canceled(event[:data])
    when "subscription.revoked"   then on_subscription_revoked(event[:data])
    end
  end

  # ── 서비스별로 구현 ────────────────────────────────────────────────────────
  # data 키 참고: https://docs.polar.sh/api/v1/webhooks
  #
  # 주요 필드:
  #   order.created       → data[:customer][:email], data[:product][:id], data[:amount]
  #   subscription.*      → data[:id], data[:customer][:email], data[:current_period_end],
  #                         data[:cancel_at_period_end]

  def on_order_created(data)
    # 예: user = User.find_by(email: data[:customer][:email])
    #     user&.activate_polar!(subscription_id: data[:id])
  end

  def on_subscription_active(data)
    # 예: user = User.find_by(email: data[:customer][:email])
    #     user&.activate_polar!(
    #       subscription_id: data[:id],
    #       access_until: data[:current_period_end]&.then { Time.parse(_1) }
    #     )
  end

  def on_subscription_canceled(data)
    # cancel_at_period_end: true 면 기간 종료 후 취소
    # 예: user = User.find_by(polar_subscription_id: data[:id])
    #     user&.cancel_polar!(
    #       access_until: data[:cancel_at_period_end] ? Time.parse(data[:current_period_end]) : nil
    #     )
  end

  def on_subscription_revoked(data)
    # 즉시 취소
    # 예: user = User.find_by(polar_subscription_id: data[:id])
    #     user&.cancel_polar!
  end
end
