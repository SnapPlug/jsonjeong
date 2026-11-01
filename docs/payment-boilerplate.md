# 결제 모듈 보일러플레이트

각 서비스에 복붙해서 쓰는 결제 연동 템플릿 모음.

---

## 어떤 걸 써야 하나?

| | Polar | 포트원 V2 |
|---|---|---|
| 카카오페이·네이버페이 | ❌ | ✅ |
| 해외 카드 (Visa·Mastercard) | ✅ | ✅ |
| 한국 사업자 등록 | **불필요** | **필요** |
| 세금 처리 | 자동 (MoR) | 직접 |
| 가입비 | 무료 | 무료 |
| 수수료 | 결제액의 ~4% | 카카오 3.2% / 네이버 2.5% |

---

## Polar (해외카드, 사업자 불필요)

### 파일 구조

```
docs/polar/
  polar_controller.rb          → app/controllers/webhooks/polar_controller.rb
  polar_subscribable.rb        → app/models/concerns/polar_subscribable.rb
  migration_polar_events.rb    → db/migrate/TIMESTAMP_create_polar_events.rb
  migration_add_polar_to_users.rb → db/migrate/TIMESTAMP_add_polar_to_users.rb
  snippets.rb                  → Gemfile / routes.rb / user.rb 에 추가할 조각
```

### 적용 순서

```bash
# 1. gem 추가
echo 'gem "svix"' >> Gemfile && bundle install

# 2. 파일 복사
cp docs/polar/polar_controller.rb app/controllers/webhooks/
cp docs/polar/polar_subscribable.rb app/models/concerns/

# 3. 마이그레이션 (파일명 타임스탬프 붙이기)
cp docs/polar/migration_polar_events.rb db/migrate/$(date +%Y%m%d%H%M%S)_create_polar_events.rb
cp docs/polar/migration_add_polar_to_users.rb db/migrate/$(date +%Y%m%d%H%M%S)_add_polar_to_users.rb

# 4. 마이그레이션 실행
bin/rails db:migrate

# 5. routes.rb 에 추가
#    post "webhooks/polar", to: "webhooks/polar#receive"

# 6. user.rb 에 추가
#    include PolarSubscribable
```

### 필요한 ENV

```
POLAR_WEBHOOK_SECRET=whsec_...   # Polar 대시보드 → Webhooks → Signing secret
```

### 웹훅 핸들러 구현

`app/controllers/webhooks/polar_controller.rb` 하단의 `on_*` 메서드를 서비스에 맞게 채운다.

```ruby
def on_subscription_active(data)
  user = User.find_by(email: data[:customer][:email])
  user&.activate_polar!(
    subscription_id: data[:id],
    access_until: data[:current_period_end]&.then { Time.parse(_1) }
  )
end
```

---

## 포트원 V2 (카카오페이·네이버페이, 한국 사업자 필요)

### 파일 구조

```
docs/portone/
  payments_controller.rb        → app/controllers/payments_controller.rb
  portone_webhook_controller.rb → app/controllers/webhooks/portone_controller.rb
  payment_controller.js         → app/javascript/controllers/payment_controller.js
  portone_payable.rb            → app/models/concerns/portone_payable.rb
  migration.rb                  → db/migrate/TIMESTAMP_create_portone_tables.rb
  snippets.rb                   → routes.rb / importmap.rb / user.rb 에 추가할 조각
```

### 적용 순서

```bash
# 1. 파일 복사
cp docs/portone/payments_controller.rb app/controllers/
cp docs/portone/portone_webhook_controller.rb app/controllers/webhooks/
cp docs/portone/payment_controller.js app/javascript/controllers/
cp docs/portone/portone_payable.rb app/models/concerns/

# 2. 모델 파일 생성
echo 'class PortonePayment < ApplicationRecord; belongs_to :user; end' > app/models/portone_payment.rb
echo 'class PortoneEvent < ApplicationRecord; end' > app/models/portone_event.rb

# 3. 마이그레이션
cp docs/portone/migration.rb db/migrate/$(date +%Y%m%d%H%M%S)_create_portone_tables.rb
bin/rails db:migrate

# 4. routes.rb 에 추가 (snippets.rb 참고)
# 5. config/importmap.rb 에 추가 (snippets.rb 참고)
# 6. user.rb 에 include PortonePayable 추가
```

### 필요한 ENV (5개)

```
PORTONE_STORE_ID=store-xxxxxxxx            # 콘솔 → 결제 연동
PORTONE_API_SECRET=...                     # 콘솔 → 결제 연동 탭
PORTONE_WEBHOOK_SECRET=...                 # 콘솔 → 웹훅 관리 → 시크릿 발급
PORTONE_CHANNEL_KEY_KAKAOPAY=channel-key-xxx
PORTONE_CHANNEL_KEY_NAVERPAY=channel-key-yyy
```

### 뷰에서 결제 버튼 사용법

```erb
<%= tag.div data: {
  controller: "payment",
  payment_store_id_value:     ENV["PORTONE_STORE_ID"],
  payment_channel_key_value:  ENV["PORTONE_CHANNEL_KEY_KAKAOPAY"],
  payment_order_name_value:   "서비스 이용권",
  payment_amount_value:       9900,
  payment_redirect_url_value: payments_complete_url
} do %>
  <%= tag.button "카카오페이로 결제", data: { action: "click->payment#pay" },
      class: "btn-primary" %>
<% end %>
```

### 웹훅 핸들러 구현

`app/controllers/webhooks/portone_controller.rb` 하단의 `on_*` 메서드를 서비스에 맞게 채운다.

```ruby
def on_paid(data)
  user = PortonePayment.find_by(payment_id: data[:paymentId])&.user
  user&.activate_portone!(payment_id: data[:paymentId], amount: 9900)
end
```

### 포트원 콘솔 체크리스트

- [ ] 카카오페이 가맹 신청 (콘솔 → 결제 연동 → 채널 추가)
- [ ] 네이버페이 결제형 가맹 신청 (주문형 아님)
- [ ] 웹훅 URL 등록: `https://your-domain.com/webhooks/portone`
- [ ] 웹훅 버전: **2024-04-25** (최신) 선택
- [ ] 채널 키 발급 후 ENV 업데이트

---

## new-saas 스크립트와 연동

새 서비스 생성 시 자동 적용:

```bash
new-saas my-service --payment portone   # 포트원 V2
new-saas my-service --payment polar     # Polar
```

인터랙티브 모드에서는 프롬프트로 선택 가능.
