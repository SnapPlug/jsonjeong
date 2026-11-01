// 복사 위치: app/javascript/controllers/payment_controller.js
//
// 사용법 (ERB):
//   <%= tag.div data: {
//     controller: "payment",
//     payment_store_id_value:     ENV["PORTONE_STORE_ID"],
//     payment_channel_key_value:  ENV["PORTONE_CHANNEL_KEY_KAKAOPAY"],
//     payment_order_name_value:   "서비스 이용권",
//     payment_amount_value:       9900,
//     payment_redirect_url_value: payments_complete_url
//   } do %>
//     <%= tag.button "카카오페이로 결제", data: { action: "click->payment#pay" } %>
//   <% end %>
//
// importmap 설정 필요 (snippets.rb 참고)

import { Controller } from "@hotwired/stimulus"
import * as PortOne from "@portone/browser-sdk/v2"

export default class extends Controller {
  static values = {
    storeId:     String,
    channelKey:  String,
    orderName:   String,
    amount:      Number,
    redirectUrl: String,
  }

  async pay(event) {
    event.preventDefault()

    const btn = event.currentTarget
    btn.disabled = true
    btn.textContent = "처리 중..."

    try {
      const paymentId = `payment-${crypto.randomUUID()}`

      const response = await PortOne.requestPayment({
        storeId:     this.storeIdValue,
        channelKey:  this.channelKeyValue,
        paymentId,
        orderName:   this.orderNameValue,
        totalAmount: this.amountValue,
        currency:    "CURRENCY_KRW",
        redirectUrl: this.redirectUrlValue,  // 모바일 필수. 결제 후 서버로 리다이렉트
      })

      // redirectUrl 방식이므로 모바일에서는 이 아래 코드에 도달하지 않음
      // PC에서 팝업 닫힌 경우 (반환값 방식)
      if (response?.code) {
        alert(response.message)
        btn.disabled = false
        btn.textContent = "다시 결제하기"
      }
    } catch (err) {
      alert("결제 중 오류가 발생했습니다.")
      btn.disabled = false
      btn.textContent = "다시 결제하기"
    }
  }
}
