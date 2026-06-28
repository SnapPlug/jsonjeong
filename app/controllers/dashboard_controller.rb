class DashboardController < ApplicationController
  allow_unauthenticated_access only: :index

  # Service status drives card badge color + CTA copy.
  # :planning → not started · :building → in progress · :shipped → live with paying users
  Service = Data.define(:name, :tagline, :subline, :emoji, :status, :mrr_usd, :path, :cta_label, :cta_source, :trust, :concept, :demo_video, :demo_poster) do
    def initialize(trust: nil, concept: nil, demo_video: nil, demo_poster: nil, **) = super
  end

  PROFILE = {
    name: "Json Jeong",
    location: "대한민국 제주",
    revenue: "월 매출 0원",
    quote: "한국에서 AI 팀원을 만드는 일을 합니다. 이제 그걸 제품으로, 공개적으로 출시합니다 — 바이브코딩으로 만든 앱을 지켜주는 것부터.",
    newsletter_count: "1",
    newsletter_name: "Snap to It",
    newsletter_tagline: "무엇을 출시했고, 무엇이 터졌고, 계속 발견하는 보안 구멍들. 군더더기 없이.",
    threads_url: "https://www.threads.net/@snapplug.app",
    x_url: "https://x.com/jasonjeongio"
  }.freeze

  # Update PUBLIC_BET weekly. Keep this honest — do NOT inflate.
  PUBLIC_BET = {
    day: 1,
    total_days: 90,
    current_mrr_usd: 0,
    goal_mrr_usd: 1_000,
    headline: "공개 도전",
    promise: "90일 안에 월 0원 → $1,000 MRR.",
    rules: "광고 없이, 청중 없이, 편법 없이. 실패하면 영원히 인용해서 놀려도 됩니다."
  }.freeze

  SERVICES = [
    Service.new(
      name: "SnapDeck",
      tagline: "AI로 만든 앱을 위한 보안 안전망.",
      subline: "활짝 열린 RLS, 번들에 노출된 키, 아무나 접근하는 라우트 — SnapDeck이 누가 먼저 찾기 전에 쉬운 말로 잡아냅니다.",
      trust: "내 컴퓨터에서 실행됩니다. 키는 절대 밖으로 나가지 않습니다.",
      concept: "보안 스캐너",
      demo_video: "/snapdeck-demo.mp4?v=2",
      demo_poster: "/snapdeck-demo-poster.jpg",
      emoji: "🔒",
      status: :building,
      mrr_usd: 0,
      path: "https://snapdeck.jsonjeong.com",
      cta_label: "사이트 보기 →",
      cta_source: "snapdeck_card"
    ),
    Service.new(
      name: "SnapMusk",
      tagline: "맥북 노치에 사는 AI 타임박싱 비서.",
      subline: "'헤이 머스크' 한마디로 깨우고, 온디바이스 음성인식(WhisperKit)으로 받아적고, Claude가 하루를 타임박싱해줍니다.",
      concept: "macOS 앱",
      emoji: "🎙️",
      status: :building,
      mrr_usd: 0,
      path: "https://github.com/SnapPlug/snapmusk",
      cta_label: "GitHub →",
      cta_source: "snapmusk_card"
    ),
    Service.new(
      name: "Snap Teleprompter",
      tagline: "맥북 노치를 텔레프롬프터로.",
      subline: "노치 영역에 대본이 스르륵 흘러갑니다. 카메라를 보면서 자연스럽게 읽으세요.",
      concept: "macOS 앱",
      emoji: "📜",
      status: :shipped,
      mrr_usd: 0,
      path: "https://github.com/SnapPlug/snap-teleprompter",
      cta_label: "GitHub →",
      cta_source: "teleprompter_card"
    ),
    Service.new(
      name: "Supabase 바이브코딩 가이드",
      tagline: "Claude Code로 Supabase 만들 때 터지는 문제 모음.",
      subline: "바이브코딩으로 Supabase 백엔드를 짜다 만나는 문제와 해결책을 정리했습니다. 무료, 오픈소스.",
      concept: "오픈소스 가이드",
      emoji: "📖",
      status: :shipped,
      mrr_usd: 0,
      path: "https://github.com/SnapPlug/supabase-vibe-coding-guide",
      cta_label: "GitHub →",
      cta_source: "guide_card"
    )
  ].freeze

  def index
    @profile = PROFILE
    @services = SERVICES
    @bet = PUBLIC_BET
  end
end
