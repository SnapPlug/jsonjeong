# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 언어 정책 (한국어 전환 — 2026-06-17 전면 피벗)

| 레이어 | 언어 |
|---|---|
| 사용자 ↔ Claude 대화 | **한글** |
| 내부 메모, CLAUDE.md, 코드 주석 | **한글** (코드 식별자, 커밋 메시지는 영문) |
| **jsonjeong.com 랜딩 — UI/카피/메타데이터** | **한국어** (`lang="ko"`, `og:locale ko_KR`) |
| **제품 (SnapDeck 등) — UI/카피** | **한국어** |
| 뉴스레터 (Snap to It / beehiiv) | **한국어** |
| 마케팅 (X·Threads·블로그·영상) | **한국어** |

**브랜드·제품명은 영문 유지** (SnapDeck, SnapMusk, Snap Teleprompter, Snap to It, jsonjeong). 기술 용어(RLS, API, Supabase 등)도 영문 그대로.

이유: **글로벌 영어 라인 폐기, 한국 시장으로 전면 피벗** (2026-06-17). 이전엔 jsonjeong·SnapDeck을 영어-글로벌(인디 바이브코더, X로 오디언스)로 운영했으나, 한국 시장·한국어로 통합. 모든 대외 카피(랜딩·뉴스레터·마케팅)는 한국어. @jasonjeongio X 계정의 영어 전략·기존 영어 콘텐츠는 한국어로 재정렬 대상.

## 운영 사이클 (단일 루프)

마케팅 + 세일즈 + 개발 + 서비스 운영 + 유지보수가 **하나의 사이클**로 돈다. 분리된 워크스트림 없음.

- **빌드 인 퍼블릭**: 의미 있는 개발 단계마다 X 콘텐츠 생산. "이 변경을 X에 어떻게 풀까?" 가 작업 끝의 디폴트 질문
- **OSMU (One Source Multi Use)**: 한 번 만든 콘텐츠를 X 스레드 → 블로그 → 영상 → 뉴스레터 → 랜딩 카피 로 재사용
- **콘텐츠 생성 도구**: 마케팅·바이럴·런치 카피는 `/go-viral-or-die` 스킬을 invoke 해서 만든다. 즉흥 작성 금지
- **사이클 진입 신호**: 사용자가 "이거 X에 올릴까", "콘텐츠 만들어", "런치 준비" 같은 말을 하면 `/go-viral-or-die` 자동 invoke 후보

## 프로젝트 목적

바이브 코딩(vibe coding)으로 개발하는 사람들을 위한 여러 서비스를 한 곳에서 보여주는 메인 대시보드. https://marclou.com 을 모델로 한다 — 목적(여러 사이드 프로젝트/서비스를 인덱싱하는 단일 랜딩 페이지)과 UI/UX(동일한 비주얼 언어, 레이아웃, 인터랙션 패턴) 양쪽 모두.

세부 서비스(대시보드에 노출되는 개별 프로젝트)는 단계별로 사용자가 안내한다. 임의로 서비스를 만들어 채우지 말고, 사용자의 사양을 기다린다.

## 기술 스택 (확정)

핵심 철학: **단순함 = AI 친화**. 영상([헤이제임스, "프롬프트 문제가 아니라 프레임워크 문제"](https://youtu.be/6cE6494X22w))의 주장대로, 분리된 스택 대신 풀스택 모놀리스로 간다. Rails 8 기본값에서 벗어나지 않는다 — 관례 일탈은 AI 가 패턴을 못 잡게 만든다.

| 영역 | 선택 |
|---|---|
| 프레임워크 | Rails 8 |
| Ruby | 3.3 이상 |
| DB | SQLite (개발/소규모 프로덕션). 필요해질 때만 Postgres |
| 인증 | Rails 8 내장 인증 generator (`bin/rails generate authentication`). Devise 미사용 |
| 백그라운드 잡 | Solid Queue |
| 캐시 | Solid Cache |
| WebSocket | Solid Cable |
| CSS | Tailwind CSS (`tailwindcss-rails`) |
| JS | Import maps + Turbo + Stimulus (Hotwire). 빌드 도구 없음 |
| 테스트 | Minitest (Rails 기본) |
| 결제 | Polar (Merchant of Record). Stripe 한국 진입 장벽 회피. `pay` gem 미사용 — Polar 웹훅 직접 처리 |
| 배포 | Kamal 2 |
| 도메인 | jsonjeong.com (Cloudflare 등록 + DNS) |

외부 Redis/Node 빌드 체인 없음.

## 레포 구조 (확정)

**이 레포(jsonjeong.com)는 인덱스 사이트일 뿐.** 모든 세부 SaaS 는 각각 **별도 Rails 8 앱 · 별도 레포 · 별도 도메인**. 마크 루 패턴.

```
~/projects/
  jsonjeong/    ← 이 레포. 카드 그리드 + 프로필 + 뉴스레터. 도메인 jsonjeong.com
  snapdeck/    ← 별도 Rails 앱. 도메인 snapdeck.com 등
  snapteam/    ← 별도
  ...           ← 새 서비스마다 별도 레포
```

- 이 레포(jsonjeong) 의 [DashboardController](app/controllers/dashboard_controller.rb) `SERVICES` 의 `path:` 는 **외부 URL** (예: `https://snapdeck.com`). 내부 라우트 X
- 각 SaaS 레포는 자기 CLAUDE.md · DB · 인증 · 결제 보유. 공유 0
- 인증 / 결제 / 파싱 등 헬퍼는 처음엔 복붙. 3번째 서비스 시점에 internal gem 추출 검토 (premature abstraction 회피)

**왜 모놀리스 아닌가:** 블래스트 반경 격리, 독립 배포, 도메인·브랜드 강화, 결제·데이터 완전 분리, 매각 가능 (마크 루 매각 사례). 초기에 모놀리스로 결정했으나 마크 루 패턴 재검토로 뒤집음 (2026-05-13).

## 환경

- Ruby 3.3.11 (`.ruby-version`, `mise.toml` 에 고정). `mise` 가 디렉터리 진입 시 자동 활성화.
- Rails 8.1.3.
- DB 는 SQLite. `db/migrate/` 에 사용자/세션 테이블 마이그레이션이 이미 적용됨.

새 머신에서 셋업: `brew install mise` → `eval "$(mise activate zsh)"` 를 `~/.zshrc` 에 추가 → 프로젝트 디렉터리로 이동 → `mise install` → `bundle install` → `bin/rails db:prepare`.

## 자주 쓰는 명령

```bash
bin/dev                 # 개발 서버 (Rails + Tailwind watcher)
bin/rails console       # REPL
bin/rails test          # 전체 테스트
bin/rails test test/models/user_test.rb  # 단일 파일
bin/rails test test/models/user_test.rb:42  # 단일 라인
bin/rails db:migrate    # 마이그레이션
bin/rails db:rollback   # 직전 마이그레이션 롤백
bin/rubocop             # 린트 (Rails Omakase 규칙)
bin/rubocop -A          # 린트 자동 수정
bin/brakeman            # 보안 정적 분석
bin/bundler-audit       # gem 취약점 점검
bin/rails routes        # 라우트 확인
bin/rails routes -g <name>  # 라우트 검색
```

## 아키텍처 (이 레포 = jsonjeong 인덱스 사이트)

Rails 8 기본값만 사용. 추가 패턴/추상화 없음.

- **루트(`/`)**: [DashboardController](app/controllers/dashboard_controller.rb) 가 marclou.com 스타일 카드 그리드 노출. `SERVICES` 의 `path:` 는 외부 URL
- **인증**: Rails 8 내장. `User`, `Session` 모델 + `SessionsController`, `PasswordsController` + `Authentication` concern. 인덱스 사이트는 현재 사실상 게스트 only (뉴스레터 가입만)
- **백그라운드 잡 / 캐시 / WebSocket**: Solid Queue / Cache / Cable. 외부 Redis 없음
- **프런트엔드**: Hotwire (Turbo + Stimulus) + Tailwind. 빌드 도구 없음

새 세부 서비스 추가 워크플로 (이 레포에선 카드만 추가):
1. 새 레포에서 `rails new <name> --css tailwind` 로 별도 앱 시작 (별도 디렉터리)
2. 새 도메인 등록 + Cloudflare DNS
3. 이 레포의 `SERVICES` 상수에 새 `Service` 한 줄 추가 — `path:` 는 외부 도메인 URL

## 코드 스타일

- Rails Omakase RuboCop 규칙(`.rubocop.yml`) 을 그대로 따른다. 커스텀 룰 추가 금지.
- "설정보다 관례": 새 패턴을 만들지 말고 Rails 관례를 따른다. AI 가 패턴을 못 잡는 순간 영상에서 경고한 복잡도 지옥이 시작된다.
- 컨트롤러는 얇게, 비즈니스 로직은 모델에. Service Object 같은 추가 레이어는 명백히 필요할 때만.

## 디자인 레퍼런스

비주얼 타깃은 https://marclou.com . UI 구현 시 레이아웃 구조, 타이포그래피, 여백, 서비스 목록의 카드 그리드 패턴을 그대로 맞춘다. 기억에 의존하지 말고 `/browse` (gstack) 로 실제 사이트를 직접 확인한다.
