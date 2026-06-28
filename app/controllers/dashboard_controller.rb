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
      status: :planning,
      mrr_usd: 0,
      path: nil,
      cta_label: "얼리 액세스 신청 →",
      cta_source: "snapdeck_card"
    )
  ].freeze

  def index
    @profile = PROFILE
    @services = SERVICES
    @bet = PUBLIC_BET
  end
end
