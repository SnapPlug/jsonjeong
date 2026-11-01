# 복사 위치: app/controllers/payments_controller.rb
#
# 흐름:
#   GET  /payments/new        → 결제 버튼 화면
#   GET  /payments/complete   → 결제 후 리다이렉트 착지 (포트원이 paymentId 쿼리로 전달)
#   POST /payments/complete   → 브라우저가 직접 결제 완료 통보 (PC 반환값 방식 fallback)

require "net/http"

class PaymentsController < ApplicationController
  before_action :require_authentication

  def new
    # view 에서 사용할 채널 키를 전달 (카카오/네이버 선택 UI 구현 시)
    @store_id        = ENV.fetch("PORTONE_STORE_ID")
    @channel_key_kakao  = ENV.fetch("PORTONE_CHANNEL_KEY_KAKAOPAY")
    @channel_key_naver  = ENV.fetch("PORTONE_CHANNEL_KEY_NAVERPAY")
    @redirect_url    = payments_complete_url
    # TODO: 상품 정보를 DB나 상수에서 가져오기
    @order_name  = "서비스 이용권"
    @amount      = 9900  # 원 단위
  end

  # 결제 완료 후 포트원이 리다이렉트하는 엔드포인트
  # GET /payments/complete?paymentId=payment-xxx
  def complete
    payment_id = params[:payment_id]

    unless payment_id
      return redirect_to new_payment_path, alert: "잘못된 접근입니다."
    end

    # 포트원 API로 실제 결제 상태 검증 (클라이언트 값 절대 신뢰 금지)
    payment = portone_get_payment(payment_id)

    if payment && payment[:status] == "PAID" && payment[:amount][:total] == expected_amount
      current_user.activate_portone!(payment_id: payment_id, amount: payment[:amount][:total])
      redirect_to root_path, notice: "결제가 완료되었습니다. 이용해 주세요!"
    else
      redirect_to new_payment_path, alert: "결제 확인에 실패했습니다. 다시 시도해 주세요."
    end
  rescue => e
    Rails.logger.error("포트원 결제 검증 실패: #{e.message}")
    redirect_to new_payment_path, alert: "결제 처리 중 오류가 발생했습니다."
  end

  private

  def portone_get_payment(payment_id)
    uri = URI("https://api.portone.io/payments/#{CGI.escape(payment_id)}")
    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "PortOne #{ENV.fetch('PORTONE_API_SECRET')}"

    res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
    return nil unless res.is_a?(Net::HTTPSuccess)

    JSON.parse(res.body, symbolize_names: true)
  end

  def expected_amount
    # TODO: DB에서 실제 주문 금액 조회. 절대 클라이언트 파라미터로 받지 말 것.
    9900
  end
end
