# 복사 위치: app/controllers/webhooks/portone_controller.rb
#
# 필수 준비:
#   ENV["PORTONE_WEBHOOK_SECRET"] — 콘솔 → 결제 연동 → 웹훅 관리 → 시크릿 발급
#   config/routes.rb 에 라우트 추가 (snippets.rb 참고)
#   migration 파일 적용 후 bin/rails db:migrate
#
# 포트원 V2는 Standard Webhooks 스펙을 사용. gem 없이 직접 검증.

class Webhooks::PortoneController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :verify_signature
  before_action :skip_if_duplicate

  def receive
    event = JSON.parse(request.raw_post, symbolize_names: true)

    PortoneEvent.create!(
      webhook_id: request.headers["webhook-id"],
      event_type: event[:type],
      payload:    event.dig(:data) || {}
    )

    dispatch(event)
    head :ok
  end

  private

  # Standard Webhooks 서명 검증
  # 스펙: https://www.standardwebhooks.com/
  def verify_signature
    wh_id  = request.headers["webhook-id"]
    wh_ts  = request.headers["webhook-timestamp"]
    wh_sig = request.headers["webhook-signature"]

    return head :unauthorized unless wh_id && wh_ts && wh_sig

    # 5분 이상 지난 요청 거부 (리플레이 공격 방지)
    if (Time.now.to_i - wh_ts.to_i).abs > 300
      return head :unauthorized
    end

    message  = "#{wh_id}\n#{wh_ts}\n#{request.raw_post}"
    secret   = Base64.decode64(ENV.fetch("PORTONE_WEBHOOK_SECRET"))
    expected = Base64.strict_encode64(OpenSSL::HMAC.digest("SHA256", secret, message))

    # 헤더에 여러 서명이 공백 구분으로 올 수 있음 (v1,<base64> 형식)
    provided = wh_sig.split(" ").map { |s| s.split(",", 2).last }
    unless provided.any? { |sig| ActiveSupport::SecurityUtils.secure_compare(sig, expected) }
      head :unauthorized
    end
  end

  # ponytail: 포트원 재시도 대비 중복 처리 방지
  def skip_if_duplicate
    head :ok if PortoneEvent.exists?(webhook_id: request.headers["webhook-id"])
  end

  def dispatch(event)
    case event[:type]
    when "Transaction.Paid"             then on_paid(event[:data])
    when "Transaction.Cancelled"        then on_cancelled(event[:data])
    when "Transaction.PartialCancelled" then on_partial_cancelled(event[:data])
    when "Transaction.Failed"           then on_failed(event[:data])
    # 알 수 없는 type: 에러 없이 무시 (포트원 스펙)
    end
  end

  # ── 서비스별로 구현 ────────────────────────────────────────────────────────
  # data 키: paymentId, storeId, transactionId (cancellationId는 취소 시)

  def on_paid(data)
    # 예: user = User.find_by_portone_payment(data[:paymentId])
    #     user&.activate_portone!(payment_id: data[:paymentId], amount: ...)
  end

  def on_cancelled(data)
    # 예: user = User.find_by_portone_payment(data[:paymentId])
    #     user&.deactivate_portone!
  end

  def on_partial_cancelled(data) = nil
  def on_failed(data)            = nil
end
