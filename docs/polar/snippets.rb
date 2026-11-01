# ─── Gemfile ────────────────────────────────────────────────────────────────
gem "svix"  # Polar 웹훅 서명 검증


# ─── config/routes.rb ───────────────────────────────────────────────────────
post "webhooks/polar", to: "webhooks/polar#receive"


# ─── app/models/user.rb ─────────────────────────────────────────────────────
include PolarSubscribable


# ─── .env / credentials ─────────────────────────────────────────────────────
# POLAR_WEBHOOK_SECRET=whsec_...   ← Polar 대시보드 → Webhooks → Signing secret
#
# Rails credentials 에 넣는 경우:
#   bin/rails credentials:edit
#   polar:
#     webhook_secret: whsec_...
#
# 그러면 polar_controller.rb 의 ENV.fetch("POLAR_WEBHOOK_SECRET") 를:
#   Rails.application.credentials.dig(:polar, :webhook_secret)
# 로 교체
