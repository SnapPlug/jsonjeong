# prompt_plan.md — Overload(계약현황·헬스체크 관제) 이전

> 확정 2026-10-14(수) Jason. 요구사항 원본: pickerel `output/2026-10-14-Overload-개선안.md`. Next.js/Vercel(`~/snapplug_observer`)을 버리고 이 앱 안에 `ops.jsonjeong.com`으로 다시 만든다.

## 결정 사항

- jsonjeong 안에 넣는다(별도 앱 아님). 서버 1GB RAM에서 컨테이너 하나 더는 무리. CLAUDE.md의 "인덱스 사이트일 뿐" 규칙에 **내부 운영 도구(ops) 예외** 한 줄을 추가한다.
- 서브도메인 `ops.jsonjeong.com`. Cloudflare 원본 인증서가 와일드카드라 인증서 작업 없음. production.rb hosts 정규식이 이미 허용.
- 기존 Rails 8 인증(`Authentication` concern, sessions)을 그대로 쓴다.
- 월 매출 차트 유지(Tailwind div 막대). 이슈·Log Drain·응답시간/에러 차트는 안 만든다. AIOS는 등록 안 함. snapdeck 컨테이너는 제거(2026-10-14 지시).
- 텔레그램은 snaptalk 봇 + **Overload 전용 새 방**. 헬스체크 결과만 보낸다(연속 2회 실패 🔴, 그 뒤 복구 🟢). 앱 예외·배포 알림은 각 Rails 앱이 직접 보낸다.
- 감시자 생존은 Healthchecks.io 데드맨 스위치(5분 주기, 10분 유예).
- 데이터: 고객사 17·계약 23·납부 42건을 `~/.config/overload/turso-export.json`에서 가져온다. 저장소에 넣지 않는다. 헬스 로그는 안 옮긴다.
- 비밀값은 `.kamal/secrets`에 `$(cat ~/.config/overload/...)` 명령형으로만.

## 단계와 검증

| 단계 | 내용 | 끝났다는 증거 |
|---|---|---|
| 0 준비 | Jason: 텔레그램 방+봇 초대, Healthchecks.io 체크, Cloudflare DNS `ops` A→69.55.54.59. 나: Turso 반출(완료), VERCEL_TOKEN 파일(완료), snapdeck 제거 | 파일 존재, `dig ops.jsonjeong.com` |
| 1 모델 | clients·contracts·payments·health_logs 마이그레이션, 모델 검증, `overload:import` 태스크 | 모델 테스트 통과, 임포트 후 17·23·42·수금 36,280,000 |
| 2 화면 | `constraints subdomain: "ops"`, Ops::BaseController(인증), 홈(숫자 4장·미수금·서비스 상태·월 매출), 고객사 상세, 새 계약(고객사 자동완성 upsert, 납부 50/50 자동), 납부·계약 상태 변경 | 컨트롤러 테스트 통과(비로그인 302, 로그인 200, 새 이름 계약 → 고객사 +1, 합계 불일치 422) |
| 3 체크 | `app/lib/telegram.rb`(snaptalk 복사), `HealthCheck::{Url,Vercel,Supabase}`, `HealthCheckJob`(판정→텔레그램→하트비트), `config/recurring.yml`(5분·정리·연체), deploy.yml `SOLID_QUEUE_IN_PUMA` | 판정 규칙 단위 테스트, 잡 테스트(HTTP·텔레그램 스텁) |
| 4 배포 | deploy.yml hosts·secrets, `kamal deploy`, 서버에서 임포트, snaptalk·jsonjeong `/up` 등록, 일주일 병행 | 홈 "지금 체크" → 텔레그램 수신, Healthchecks.io 핑 기록 |
| 5 키트 | snaptalk·jsonjeong에 `/health`(db·queue·disk JSON `failed[]`), 예외→텔레그램 구독(10분 제한), Kamal pre-deploy(bundler-audit·brakeman)·post-deploy(텔레그램) 훅. 로컬바이브랩에 복사 | `rails runner 'raise'` → 텔레그램 1통, 배포 → 🚀 한 줄 |
| 6 정리 | Vercel 프로젝트·Turso·cron-job.org·Gmail 앱 비밀번호 삭제, observer 저장소 보관, CLAUDE.md·개선안 문서 갱신 | 청구 0 |

## 진행 (2026-10-14 07:00 KST)

| 단계 | 상태 |
|---|---|
| 0 준비 | 반출·VERCEL_TOKEN·snapdeck 제거 완료. 텔레그램 완료(봇 `@snapplug_overload_bot`, 채널 "Overload"). **Healthchecks.io·DNS는 대기** — 값이 오면 `~/.config/overload/healthchecks_url`에 넣고 `kamal app boot` |
| 1 모델 | 완료. 서버 임포트 완료(18·23·42·수금 36,280,000) |
| 2 화면 | 완료. 원 서버 직결로 302→로그인 200 확인. DNS 전이라 브라우저 확인은 아직 |
| 3 체크 | 완료. 스케줄러 5분 가동 중, 감시 9곳. URL 체크 리다이렉트 추종 수정(6차 배포) |
| 4 배포 | 완료(6회). 3차 배포가 Solid Queue 스키마·연결 설정 부재로 jsonjeong.com을 약 15분 죽였고 5차에서 복구 — 원인·교훈은 pickerel 개선안 §9 |
| 5 키트 | snaptalk·jsonjeong 완료. 로컬바이브랩은 10/19 스캐폴드 때 snaptalk 파일 복사 |
| 6 정리 | 일주일 병행 뒤(10/21 이후) |

## 규칙

- 테스트 먼저(Minitest). 각 단계 끝에 `bin/rails test` 전체 통과 후 커밋.
- Rails 8 기본값·Omakase 스타일. Service Object·새 gem 없음(Net::HTTP, Solid Queue, Solid Cache만).
- 커밋은 ops 관련 파일만 골라서(`git add .` 금지 — 작업 트리에 무관한 docs 변경이 있음).
