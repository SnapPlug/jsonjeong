class DashboardController < ApplicationController
  allow_unauthenticated_access only: :index

  # Service status drives card badge color + CTA copy.
  # :planning → not started · :building → in progress · :shipped → live with paying users
  Service = Data.define(:name, :tagline, :subline, :emoji, :status, :mrr_usd, :path, :cta_label, :cta_source, :trust) do
    def initialize(trust: nil, **) = super
  end

  PROFILE = {
    name: "Json Jeong",
    location: "Jeju, South Korea",
    revenue: "$0/month",
    quote: "Quit corporate. Moved to Jeju. I shipped my first apps wide open — now I'm building the safety net I wish I'd had. $0 → $1K MRR, in public.",
    newsletter_count: "1",
    newsletter_name: "Snap to It",
    newsletter_tagline: "Weekly notes from a solo dev in Jeju: what I shipped, what broke, the security holes I keep finding, the real numbers. No fluff. No 47-agent diagrams.",
    threads_url: "https://www.threads.net/@snapplug.app",
    x_url: "https://x.com/jasonjeongio"
  }.freeze

  # Update PUBLIC_BET weekly. Keep this honest — do NOT inflate.
  PUBLIC_BET = {
    day: 1,
    total_days: 90,
    current_mrr_usd: 0,
    goal_mrr_usd: 1_000,
    headline: "The Public Bet",
    promise: "$0 → $1,000 MRR in 90 days.",
    rules: "Started with 2 followers. No paid ads, no courses, no agency.",
    threat: "If I miss it, you can quote-tweet this forever."
  }.freeze

  SERVICES = [
    Service.new(
      name: "SnapDeck",
      tagline: "The security net for the apps you built with AI.",
      subline: "RLS left wide open, keys exposed in the bundle, routes anyone can hit — SnapDeck catches it in plain English, before someone else does.",
      trust: "Runs on your machine. Your keys never leave.",
      emoji: "🔒",
      status: :planning,
      mrr_usd: 0,
      path: nil,
      cta_label: "Get early access →",
      cta_source: "snapdeck_card"
    )
  ].freeze

  def index
    @profile = PROFILE
    @services = SERVICES
    @bet = PUBLIC_BET
  end
end
