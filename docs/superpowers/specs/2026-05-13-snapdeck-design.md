# SnapDeck V1 — Design Spec

- **Status**: Approved for implementation planning
- **Date**: 2026-05-13
- **Author**: Json Jeong (jsonjeong.com)
- **Parent**: jsonjeong.com 의 첫 번째 세부 SaaS

## 1. Problem

Claude Code 사용자는 GitHub / SNS 추천을 따라 플러그인 · 스킬 · MCP · 슬래시커맨드를 빠르게 설치하지만, 며칠만 지나도 자기가 무엇을 깔았는지, 특정 슬래시가 어느 플러그인 소속인지 기억하지 못해 활용하지 못한다. Claude Code 의 내장 `/help` 는 평면 리스트라서 검색·메모·맥락이 부족하다.

## 2. Solution (one-liner)

> **Snap your Claude Code setup into a searchable deck — and never forget what you installed.**

브라우저에 `~/.claude/` 폴더를 zip 으로 드래그앤드롭하면, SnapDeck 이 모든 플러그인 / 스킬 / MCP / 슬래시커맨드를 파싱해 검색 가능한 카드 데크로 보여준다. 결제하면 메모 · 태그 · 즐겨찾기 · 영구 저장이 풀린다.

## 3. Target User

**Persona — "Indie Maker Marcus"**

- 1인 개발자 / 메이커, 글로벌 (영어 사용자), 매월 $1k-$10k MRR 목표
- Claude Code 일상 사용. X 에서 새 플러그인 / 스킬 추천을 자주 깔아봄
- "어제 본 그 슬래시 뭐였더라" 가 주 1회 발생
- 일회성 결제 친화 (구독 피로)
- 라이프타임 라이선스에 $29-$99 지출 의향

## 4. V1 Scope (5 features)

### 4.1 Drag-Drop Upload (게스트 OK)

- 사용자가 `~/.claude/` 폴더를 zip 으로 압축해 브라우저에 드래그
- Solid Queue 백그라운드 잡으로 비동기 파싱, Turbo Streams 로 진행 상황 푸시
- 파싱 대상:
  - `plugins/<name>/SKILL.md` 또는 `plugins/<name>/plugin.json` — 플러그인 메타
  - `skills/<name>/SKILL.md` — 스킬 (YAML 프론트매터의 `name`, `description` 추출)
  - `commands/*.md` — 사용자 슬래시 커맨드
  - `agents/*.md` — 서브에이전트
  - `mcp.json` 또는 settings 의 `mcpServers` — MCP 서버 정보
- **게스트 영속 정책**: 게스트 카탈로그는 **DB에 저장**하되 `claim_token` (랜덤 32바이트) + `claimed_at IS NULL` + `expires_at = created_at + 24.hours` 로 표시. 쿠키 `signed cookie [:snapdeck_claim_token]` 에 토큰 저장. 만료 카탈로그는 `CatalogCleanupJob` (매시간 Solid Queue cron) 으로 삭제
- 결제 시 쿠키의 `claim_token` 으로 카탈로그 찾아 `user_id` 세팅 + `claimed_at` 기록
- zip 사이즈 한도: 50MB 압축, 200MB 압축 해제 총량, 항목당 20MB

**보안 (zip-slip / zip-bomb 대응):**
- Ruby 표준 라이브러리 `Zip` (rubyzip gem) 사용. 별도 `SafeUnzip` 모듈 작성
- 각 엔트리에 대해: ① `entry.name` 정규화 후 `..` 또는 절대경로(`/` 시작) 거부, ② symlink 엔트리 거부, ③ 항목당 압축 해제 크기 cap 20MB (zip-bomb 가드), ④ 총합 cap 200MB
- 검증 실패 시 잡 전체 실패 + 사용자에게 명확한 에러 메시지

### 4.2 Search

- 통합 검색 — 슬래시 이름 / 키워드 / 설명 본문 / 출처 플러그인
- 결과 카드: 항목명 + 종류(plugin/skill/slash/mcp/agent) + 출처 + 짧은 설명
- 인덱스: SQLite FTS5 가상 테이블 (Rails 8 의 `sqlite3` gem 지원)
- "그 슬래시 뭐였지" 가 핵심 시나리오 — 결과 즉시 노출, 클릭하면 상세

### 4.3 상세 페이지

- 각 항목의 풀 SKILL.md / description / 매개변수 / 예시
- 어느 플러그인/패키지 소속인지 명시 + 원본 GitHub 링크 (있으면)
- 같은 카탈로그 안의 관련 항목 (같은 플러그인 / 같은 태그) 사이드 리스트
- URL: `/items/:id` (개인) / `/library/<kind>/<slug>` (공개)

### 4.4 메모 · 태그 · 즐겨찾기 (결제 후, 영속)

- 결제 사용자만 — 항목별 노트 (markdown), 자유 태그, ⭐ 즐겨찾기
- 결제는 Polar Checkout 세션 → 웹훅 (`order.created`) 으로 `User` + `Purchase` 자동 생성
- **인증 — Magic Link**: 결제 이메일로 magic link 발송. 별도 회원가입 폼 없음
  - 토큰 생성: `User#generate_token_for(:login, expires_in: 30.minutes)` (Rails 8 `generates_token_for` 사용 — DB 컬럼 불필요, 사용자 속성 변경으로 무효화)
  - URL: `/sessions/magic?token=<signed_token>` → `SessionsController#magic` 가 `User.find_by_token_for(:login, token)` 으로 검증 후 `Session` 생성
  - 단일 사용 보장: 매번 magic link 사용 시 `User#last_signed_in_at` 갱신 → `generates_token_for` 의 `magic_token_key` 가 이 값을 포함하므로 이전 토큰 자동 무효화
  - 만료/사용된 링크 → "Link expired" 페이지 + 이메일 재입력 후 새 magic link 재발송 폼
- **게스트 카탈로그 클레임**: 결제 완료 시점에 쿠키의 `claim_token` 이 있으면 해당 `Catalog.user_id` 를 새 user 로 세팅 (§4.1 참조)

### 4.5 공개 카탈로그 (Library)

- `/library/<kind>/<slug>` 에 익명·공개 카탈로그 — "어떤 플러그인이 어떤 슬래시를 노출하는가" 의 백과사전
- **V1 시드**: Json Jeong 본인의 `~/.claude/` 데이터를 import. 사용자 0 명일 때도 페이지에 콘텐츠 존재
- **V2 자동 누적은 opt-in 필수**: 결제 사용자가 카탈로그 설정에서 명시적으로 opt-in 해야만, 그 카탈로그의 공개 가능한 항목(오픈소스 플러그인의 메타데이터)만 익명 합산. 메모 · 태그 · 이름은 절대 공개 X
- 중복 제거: `content_hash` (SKILL.md 본문 SHA256) 기준
- `slug` 유일성: `(kind, slug)` 복합 unique index — kind 가 다르면 동일 slug 허용
- SEO 자산 — 구글에서 `"claude code /xxx"` 검색 시 우리 페이지 노출 가능

## 5. Out of V1 Scope

- AI 자연어 검색 ("이미지 변환하는 게 뭐였지?" → 추천) — V2
- 사용 통계 (자주 쓰는 / 한 번도 안 쓴) — V2
- CLI 동기화 도구 (`snapdeck sync`) — V2
- 다른 IDE 지원 (Cursor / Codex / Aider) — V3+
- 팀 공유 / 콜라보레이션 — 검토 후 결정
- 사용자 ↔ 사용자 추천 (소셜) — V3+

## 6. User Journey

```
랜딩 /
   │  드래그앤드롭 → Solid Queue 잡 → Turbo Streams 진행 상황
   ▼
세션 카탈로그 (게스트, 검색·상세 자유)
   │  "메모/태그 영구 저장하려면" CTA
   ▼
Polar Checkout (외부 페이지)
   │  결제 완료 → 웹훅 → User + Purchase 생성 + magic link 이메일
   ▼
계정 활성 (영구 저장, 메모/태그/즐겨찾기 가능, 여러 셋업 비교)
```

## 7. Technical Architecture

SnapDeck 은 **별도 Rails 8 앱 · 별도 도메인 (예: snapdeck.com) · 별도 레포** 로 운영된다 (인덱스 jsonjeong.com 의 [repo-structure](~/.claude/projects/-Users-jason-jason/memory/repo_structure.md) 정책). 루트 namespace 사용 — `Catalog`, `Item` 등 모델·컨트롤러는 모두 앱 루트 레벨.

### 7.1 Routes

```ruby
# config/routes.rb
root "uploads#new"

resources :catalogs, only: [:show] do
  resources :items, only: [:show, :index]
end
resources :uploads, only: [:new, :create]
resources :memberships, only: [:new, :create]   # GET new = 가격 페이지, POST create = Polar checkout 리디렉트
post "webhooks/polar" => "webhooks#polar"       # Polar webhook endpoint (HMAC 검증)

# Magic-link login
resource :session, only: [:destroy]
resources :magic_links, only: [:new, :create]   # 새 magic link 발송 폼
get "sessions/magic" => "sessions#magic"         # /sessions/magic?token=...

# Public library — kind 별로 슬러그 충돌 회피
get "library" => "library#index", as: :library
get "library/:kind/:slug" => "library#show", as: :library_item,
    constraints: { kind: /plugin|skill|slash|mcp|agent/ }
```

### 7.2 Models

| Model | Purpose / Columns |
|---|---|
| `User`, `Session` | Rails 8 내장 인증 (이미 존재). `User#generates_token_for(:login) { last_signed_in_at }` 추가 — 사용자 로그인 시 토큰 무효화 |
| `Catalog` | 업로드된 `~/.claude/` 스냅샷. `user_id` (nullable), `name`, `uploaded_at`, `claim_token` (string, indexed), `claimed_at` (datetime, null), `expires_at` (datetime, null — 게스트만) |
| `Item` | `catalog_id`, `kind` (enum: plugin/skill/slash/mcp/agent), `name`, `slug`, `body` (markdown), `metadata` (JSON), `source_path`, `content_hash` (SHA256). Indexes: `(catalog_id)`. `(kind, slug)` 의 유일성은 이 모델에 두지 않음 — 동일 항목이 사용자별 카탈로그에 중복 존재할 수 있으므로. 유일성은 `LibraryItem` 에만 적용 |
| `LibraryItem` | 공개 카탈로그 항목 (Library 페이지용). V1 시드 = 본인 데이터. `kind`, `name`, `slug`, `body`, `metadata`, `content_hash` (unique). `Item` 과 분리해 사용자 개인 데이터 누출 방지 |
| `Note` | 결제 사용자의 항목별 메모. `user_id`, `item_id`, `body` (markdown). Unique `(user_id, item_id)` |
| `Tag` | 사용자별 태그 라벨. `user_id`, `name`. Unique `(user_id, name)` |
| `Tagging` | 태그-항목 join. `tag_id`, `item_id`. Unique `(tag_id, item_id)` |
| `Favorite` | `user_id`, `item_id`. Unique `(user_id, item_id)` |
| `Purchase` | Polar order. `user_id`, `polar_order_id` (string, **unique index**), `email`, `lifetime` (bool, default true), `refunded_at` (datetime, null), `created_at` |

### 7.3 Background Jobs (Solid Queue)

- `ParseUploadJob(catalog_id)` — `Catalog` 가 보관 중인 zip blob 을 `SafeUnzip` 으로 풀고 항목 파싱 + FTS 인덱스 인서트. Turbo Streams 로 진행 상황 푸시:
  - 게스트 채널: `catalog:<claim_token>`. 채널 구독 시 컨트롤러가 signed cookie 의 `claim_token` 과 채널명을 일치 검증 (`turbo_stream_from "catalog:#{cookies.signed[:snapdeck_claim_token]}"`) — 다른 게스트의 진행 상황을 엿보지 못하게
  - 결제 사용자 채널: `catalog:<id>:user:<uid>`. `current_user.id` 와 카탈로그 소유자 일치 검증
- `SyncToLibraryJob(catalog_id)` — opt-in 한 결제 카탈로그의 공개 가능 항목을 `LibraryItem` 으로 머지 (V1 에서 본인 시드만 실행, V2 에서 일반 사용자 opt-in 활성화)
- `CatalogCleanupJob` — Solid Queue cron (시간당) — `expires_at < NOW() AND claimed_at IS NULL` 인 게스트 카탈로그 + 자식 `Item` 삭제

### 7.4 Search Index (FTS5)

- SQLite FTS5 가상 테이블: `CREATE VIRTUAL TABLE items_fts USING fts5(name, body, source_path, content='items', content_rowid='id', tokenize='unicode61 remove_diacritics 2')`
- 영문 시장이므로 `unicode61` 으로 충분 (NFKC 정규화 + diacritics 제거). 형태소 분석 불필요
- `Item` 라이프사이클 훅:
  - `after_create_commit`: FTS row insert
  - `after_update_commit`: `saved_change_to_name? || saved_change_to_body? || saved_change_to_source_path?` 일 때만 `INSERT INTO items_fts(items_fts, rowid, name, body, source_path) VALUES('delete', ...)` 후 재인서트
  - `after_destroy_commit`: FTS row 삭제 (`INSERT ... VALUES('delete', ...)`)
- 초기 백필: `ParseUploadJob` 마지막 단계에서 신규 `Item` 들을 한꺼번에 `INSERT INTO items_fts SELECT id, name, body, source_path FROM items WHERE catalog_id = ?`
- `LibraryItem` 도 별도 FTS 테이블 `library_items_fts` 같은 방식
- 검색 컨트롤러: `LIKE` 가 아닌 FTS5 `MATCH` + ranking (`bm25()`)

### 7.5 Payment Integration

- 체크아웃 시 `Pricing.current_link` 가 `Purchase.where(refunded_at: nil).count` 기준으로 early_bird ($29) 또는 정가 ($49) Polar 링크 반환. 사용자를 해당 링크로 리다이렉트
- 웹훅 엔드포인트 `POST /webhooks/polar` — HMAC 서명 검증 (`POLAR_WEBHOOK_SECRET`). 서명 실패 → 401. 검증 실패 시 어떤 상태도 변경 X

**이벤트 처리 (idempotent):**

| Event | Handler |
|---|---|
| `order.created` | ① `polar_order_id` 로 기존 Purchase 조회 — 있으면 200 OK 즉시 반환 (idempotent). ② 이메일로 User 찾거나 생성. ③ `Purchase.create!(polar_order_id:, user:, email:, lifetime: true)` (unique index 로 중복 보호). ④ 게스트 `claim_token` 이 본문에 동봉돼 있으면 (Polar metadata 로 전달) 해당 Catalog 클레임. ⑤ magic link 생성 → ActionMailer 로 결제 이메일 발송 |
| `order.refunded` | `Purchase#update!(refunded_at: Time.current)`. lifetime 접근 자동 차단 (`User#lifetime?` 가 `purchases.where(refunded_at: nil).any?`) |
| 기타 이벤트 | 로그만 기록, 200 OK |

- 중복 이벤트는 Polar 가 재시도하므로, 모든 핸들러는 idempotent. `Purchase.polar_order_id` 의 unique index 가 마지막 방어선
- 환경 변수: `POLAR_ACCESS_TOKEN`, `POLAR_WEBHOOK_SECRET`, `POLAR_CHECKOUT_LINK_EARLY_BIRD`, `POLAR_CHECKOUT_LINK_REGULAR`

### 7.6 Tech Constraints

- Rails 8 기본값 유지 (Solid 트리오, SQLite, Hotwire). 외부 Redis/Node 빌드 체인 없음
- 사이트/UI/카피 영문 only. 마케팅도 영문 only
- Tailwind v4 system sans-serif. Pretendard 등 한글 폰트 X

## 8. Pricing & Licensing

| Plan | Price | Includes |
|---|---|---|
| Guest | Free | Drag-drop, 검색, 상세 — 24시간 게스트 카탈로그 유지 |
| Lifetime (early bird, 첫 100명) | **$29** | 모든 V1 기능 + 영구 저장 + V2 이후 추가되는 모든 **비-사용량 기반** 기능 |
| Lifetime (정가) | **$49** | 동일 |

- **가격 전환 트리거**: `Pricing` PORO 가 매 체크아웃 시점에 `Purchase.where(refunded_at: nil).count` 를 조회. 100 미만이면 early bird 링크, 100 이상이면 정가 링크 반환. 동시성: 마지막 1-2명이 race로 early bird 잡아도 OK (lifetime 이라 손익 영향 미미). 사용자에게 "100 left" 같은 카운트다운은 V1.5에서 추가
- **환불**: 7일 무조건 환불 (Polar 통해). 환불 시 `order.refunded` 웹훅으로 자동 lifetime 회수
- **Lifetime 의 범위 명시**: lifetime 은 (a) 모든 V1 기능 + (b) 영구 저장 + (c) V2 이후 추가되는 **비-사용량 기반 (non-metered)** 기능에 한정. AI 자연어 검색 같은 **사용량 기반 기능** (LLM API 토큰 비용 발생) 은 fair-use cap (예: 월 100 query) 무료 + 초과분 별도 결제. 결제 페이지·약관에 이 카브아웃을 명시
- **호스팅 비용 마진**: Rails 8 + SQLite + Hetzner CX22 (€3.79/mo) 면 사용자 수천 명까지 마진 충분. AI 사용량 기반 기능을 lifetime 에 끼워넣으면 적자 위험 → 분리 필수

## 9. Marketing Integration (운영 사이클 연결)

`MEMORY.md` 의 [operating-cycle](~/.claude/projects/-Users-jason-jason/memory/operating_cycle.md) 룰에 따라 모든 출시 단계가 X 콘텐츠로 변환된다.

**런치 콘텐츠 (`/go-viral-or-die` 스킬로 생성):**

1. **0 → 1 (V1 ship 시점)**: "I built SnapDeck because I forgot every slash I installed. Built in 7 days with Rails 8. Here's how." X 스레드 + 데모 영상
2. **공개 Library 시드 공개**: "Cataloged every Claude Code plugin I use. Free, searchable, public." (SEO 자산 + 검색 트래픽 부트스트랩)
3. **첫 결제 마일스톤**: "Got my first $29 sale 6 hours after shipping SnapDeck." 정성 콘텐츠
4. **첫 100명 마일스톤**: "100 indie makers got SnapDeck. Early bird closes." 가격 인상 트리거
5. **OSMU**: 각 X 스레드 → 블로그 (이후 추가) → 짧은 영상 → 뉴스레터 (Vibe Coding Notes)

## 10. Success Metrics (V1)

- **30 일 내 첫 결제 5건** — 시드 트래픽 (X 빌드 인 퍼블릭) + early bird 가격으로 달성 가능 가설
- **90 일 내 100 결제 (early bird 소진)** — 정가 인상 트리거. 미달 시 가격·메시지 재검토
- **공개 Library 페이지 → 구글 색인** — 출시 60일 내 indexed pages > 50

## 11. Dependencies & Risks

| Risk | Mitigation |
|---|---|
| Claude Code 가 비슷한 기능 자체 추가 → 자기 잠식 | 차별점은 **검색·메모·즐겨찾기·공개 카탈로그**. 단순 리스트 이상의 가치 |
| 무료 오픈소스 대체 등장 | 제품 표면 매끈하게 + 마케팅 (build-in-public) 으로 점유 |
| Polar 한국 결제 정책 변경 | Polar 자체가 MoR 라 한국 사업자 등록과 무관. 리스크 낮음 |
| zip 업로드 시 보안 (zip-slip, zip-bomb, symlink) | §4.1 의 `SafeUnzip` 모듈 — `..`/절대경로 거부, symlink 거부, 항목당 20MB / 총 200MB cap |
| Magic link 토큰 탈취 | 30분 만료 + `last_signed_in_at` 변경 시 자동 무효화 + 30분 내 발급 횟수 cap (V1.5) |
| 웹훅 재시도로 인한 중복 결제 처리 | §7.5 `polar_order_id` unique index + idempotent 핸들러 |
| SKILL.md 포맷 비표준화 | 베스트 에포트 파싱 + "unparseable" 항목도 노출 (수동 메모 가능) |
| 한국어 카피가 view 에 누출 | i18n locale 파일 사용 안 함 (영문 하드코딩). 시스템 테스트에서 한글 문자 정규식 검사 — `assert_no_match(/[가-힣]/, response.body)` |

## 12. Public Catalog Privacy

| Data | Public? |
|---|---|
| 항목 이름 / 설명 / 본문 (오픈소스 플러그인 메타) | ✅ Public (with content_hash dedup) |
| 어느 플러그인 / 어느 GitHub 출처 | ✅ Public |
| 사용자 이메일 / 이름 / 닉네임 | ❌ Never |
| 사용자 메모 / 태그 / 즐겨찾기 | ❌ Never |
| 어떤 사용자가 어떤 항목 가졌는지 | ❌ Never (집계도 X) |
| 사용자 슬래시커맨드 (커스텀 작성한 것) | ⚠️ Opt-in 필요 (V2 에서 결정) |

V1 에선 본인 셋업만 시드. 결제 사용자 데이터는 V2 부터 opt-in 후 합산.

## 13. Open Questions (V2+ 에 결정)

- AI 자연어 검색의 사용량 cap 구체 수치 (월 100? 200?) + 초과 시 결제 단위 — §8 lifetime carve-out 의 fair-use 범위 구체화
- CLI 동기화 도구 → §8 의 non-metered 카브아웃 정의에 따라 **lifetime 에 포함**. 별매 X. 구현 시점은 V2
- 다른 IDE (Cursor / Codex) 지원 시 데이터 모델 어떻게 확장 (`Item.kind` enum 확장 vs 새 namespace 분리)
- 팀 플랜의 의미 — 인디 메이커 타겟에 팀 플랜이 필요한가 (현재로선 NO)
