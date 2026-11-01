# ─── config/routes.rb ───────────────────────────────────────────────────────
get  "payments/new",      to: "payments#new",      as: :new_payment
get  "payments/complete", to: "payments#complete",  as: :payments_complete
post "webhooks/portone",  to: "webhooks/portone#receive"


# ─── config/importmap.rb ────────────────────────────────────────────────────
# 포트원 SDK CDN (npm 없이 Import maps 방식)
pin "@portone/browser-sdk/v2", to: "https://cdn.portone.io/v2/browser-sdk.esm.js", preload: false


# ─── app/models/user.rb ─────────────────────────────────────────────────────
include PortonePayable


# ─── app/models/portone_payment.rb (새 파일) ─────────────────────────────────
# class PortonePayment < ApplicationRecord
#   belongs_to :user
# end


# ─── .env / credentials ─────────────────────────────────────────────────────
# 콘솔 위치: 관리자 콘솔 → 결제 연동
#
# PORTONE_STORE_ID=store-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
# PORTONE_API_SECRET=<V2 전용 시크릿 — 결제 연동 탭에서 발급>
# PORTONE_WEBHOOK_SECRET=<웹훅 시크릿 — 결제알림(Webhook) 관리 탭에서 발급>
#
# 채널 키 (채널별로 별도 발급)
# PORTONE_CHANNEL_KEY_KAKAOPAY=channel-key-xxxxxxxx-xxxx
# PORTONE_CHANNEL_KEY_NAVERPAY=channel-key-yyyyyyyy-yyyy
#
# Rails credentials 에 넣는 경우:
#   bin/rails credentials:edit
#   portone:
#     store_id: store-xxx
#     api_secret: xxx
#     webhook_secret: xxx
#     channel_key_kakaopay: channel-key-xxx
#     channel_key_naverpay: channel-key-yyy
