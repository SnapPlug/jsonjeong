# jsonjeong.com 리뉴얼 — 아이디어 아카이브 계획

작성 2026-10-18 · 상태: **구현 완료, 배포 승인 대기** (브랜치 `feat/idea-archive`)

## 목표

jsonjeong.com 메인을 **$100 per Day 실험에서 나온 아이디어 아카이브**로 완전히 교체한다.
아이디어마다 카드 한 장(숫자)과 회고글 한 편(이야기)을 둔다. 한국어·영어 둘 다 쓴다.
`ops.jsonjeong.com`(계약 관제)과 `newsletter` 리디렉트는 손대지 않는다.

## 카드 한 장에 들어가는 것

| 칸 | 내용 | 출처 |
|---|---|---|
| 이름 · 한 줄 설명 | 무엇을 만들었나 | ledger |
| 상태 | 진행 중 · 멈춤 · 폐기 · 전환 | ledger + Jason 확인 |
| **검증 기간** | 시작일 → 판정일 (일). 진행 중이면 오늘까지 | ledger 날짜 |
| **쓴 돈** | 달러 (도메인·등록비 등) | ledger "쓴 돈" 열 |
| **번 돈** | 달러 | ledger "번 돈" 열 |
| 막힌 곳 | 한 줄 | ledger "막힌 곳" 열 |
| 사람이 끼어든 곳 | 한 줄 (가입·결제·인증·승인) | ledger |
| 회고글 링크 | 있을 때만 | — |

맨 위 합계 줄: **아이디어 N개 · 검증에 쓴 날 합계 · 쓴 돈 합계 · 번 돈 합계**.

검증 기간은 "일" 단위만 정확하다. ledger에 시간 기록이 없어서 몇 시간 걸렸는지는 낼 수 없다. 시간이 필요하면 지금부터 ledger에 칸을 추가해야 한다 (→ 결정 4).

## 주소

| 주소 | 화면 |
|---|---|
| `/` | 한국어 아카이브 (카드 목록) |
| `/ideas/:slug` | 한국어 회고글 |
| `/en` · `/en/ideas/:slug` | 영어판 |

두 언어 화면 모두 `hreflang`으로 서로를 가리킨다. 레이아웃의 `lang`·`og:locale`도 언어에 따라 바뀐다. 헤더에는 KO/EN 토글을 둔다.

## 구현 (Rails 기본값 안에서)

- **데이터**: `config/ideas.yml` 파일 하나에 아이디어별 숫자와 ko/en 문구를 둔다. DB·관리자 화면은 만들지 않는다. 갱신 = YAML 수정 + 배포.
- **모델**: `app/models/idea.rb`는 YAML을 읽는 일반 Ruby 객체(ActiveRecord 아님)다. `days`·합계 계산을 여기서 한다.
- **회고글**: Rails 언어별 템플릿 `app/views/ideas/retros/_<slug>.ko.html.erb` / `.en.html.erb`. 마크다운 gem은 추가하지 않는다.
- **컨트롤러**: `IdeasController#index, #show`, 라우트 `scope "(:locale)", locale: /en/`. 기본 언어는 ko.
- **삭제**: `DashboardController`의 SERVICES(SnapDeck·SnapMusk·Teleprompter·가이드), `_card`, `_faq`와 FAQ 구조화 데이터. 데모 영상 파일은 `public/`에 남긴다(서브도메인이 쓸 수 있음).
- **SEO**: sitemap·llms.txt·JSON-LD(Person + ItemList)를 새 구조로 바꾼다.
- **테스트**: `Idea` 계산(기간·합계·진행 중일 때 오늘 기준) + 두 언어 index/show가 200이고 hreflang이 있는지 확인한다.
- **디자인**: 지금 jsonjeong 라이트 테마와 프로필 사이드바 구조를 유지한다. 카드 안을 숫자 3개(기간·쓴 돈·번 돈) 중심으로 다시 짠다.

## 진행 순서

1. ledger에서 아이디어 목록과 숫자를 뽑아 `ideas.yml` 초안을 만든다 → **Jason 확인** (특히 비용을 어느 아이디어에 넣을지, 상태)
2. 모델과 테스트를 먼저 쓰고(RED), 모델을 구현한다(GREEN)
3. 컨트롤러·라우트·화면(ko/en)을 만든다 → 로컬 화면 확인
4. 회고글 첫 묶음 2–3편(ko/en) 초안 → **Jason 확인** (말투 = 발행본 기준)
5. SEO 파일 교체 → 테스트 통과 → **배포 승인** → `kamal deploy`
6. 나머지 회고글은 공개 뒤 하나씩 추가한다. 10/30 실험 종료 결산 때 한 번 더 갱신한다.

## 아이디어 목록 초안 (ledger 10/01–10/18 기준, 숫자는 1단계에서 확정)

1. 바이브코딩 보안 감사 $39 (Gumroad + Reddit)
2. 블록 쌓기 게임 광고판
3. workoutbell.com 운동 타이머 + 애드센스
4. Apify Lighthouse 액터
5. Page to PDF 크롬 확장 + Pro $9.99
6. 고객 문제·리드 목록 탐색 (Reddit, 치과)
7. Façon 파리 빵집 AI 에이전트
8. Switch Check (통신사 요금)
9. 공간서오 (제주 빵집)

## 결정이 필요한 것

1. **실험 이전 프로젝트**(SnapDeck·SnapMusk·Teleprompter·Supabase 가이드)도 아카이브에 넣을까? 넣으면 $100 per Day 밖의 기록이 섞인다.
2. **프로필 사이드바 문구**: 지금은 "AI 자동화 컨설턴트" 소개다. 아카이브에 맞춰 실험 소개로 바꿀까?
3. **회고글 첫 묶음**으로 어느 아이디어를? 추천: workoutbell(가장 멀리 감), 보안 감사(첫 실패), Façon(전환).
4. **검증 시간**: 기간(일)만 보여줄까, 앞으로 ledger에 작업 시간 칸을 추가할까?

## 결정 기록 (2026-10-18 Jason)

- 이전 프로젝트(SnapDeck·SnapMusk·Teleprompter·Supabase 가이드)도 넣는다. 쓴 돈은 $0.
- 프로필 문구를 실험 소개로 바꾼다.
- 검증 시간 = 작업 시간. $100 per Day는 세션 기록 실측(`$100_per_day/worktime.py`), 이전 프로젝트는 커밋 간격 추정.
- 공간서오는 Façon과 합쳐 "동네 빵집 AI 에이전트" 카드 하나로. 가게 이름은 공개 화면에 쓰지 않는다(동의 전).
- 회고글 첫 묶음: workoutbell, 보안 감사, 동네 빵집.
- GA4 속성 `jsonjeong.com`(snapplug_app 계정, 측정 ID G-51584NFH18) 연결. 운영 환경에서만 수집.
- SEO/GEO: hreflang(ko/en/x-default), 언어별 sitemap, llms.txt에 아이디어별 숫자, JSON-LD ItemList(메인)·Article(회고글).
