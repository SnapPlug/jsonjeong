class DashboardController < ApplicationController
  allow_unauthenticated_access only: :index

  # Service status drives card badge color + CTA copy.
  # :planning → not started · :building → in progress · :shipped → live with paying users
  Service = Data.define(:name, :tagline, :subline, :emoji, :status, :mrr_usd, :path, :cta_label, :cta_source)

  PROFILE = {
    name: "Json Jeong",
    location: "Jeju, South Korea",
    revenue: "$0/month",
    quote: "Quit corporate. Moved to Jeju. Cheating my way to $1K MRR with Rails + AI — 2 products, 90 days, no agents.",
    newsletter_count: "1",
    newsletter_name: "Vibe Coding Notes",
    newsletter_tagline: "Weekly notes from a solo dev in Jeju: what I shipped, what failed, the actual numbers. No fluff. No 47-agent diagrams."
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
      tagline: "Marie Kondo for your AI coding stack.",
      subline: "Stop drowning in skills, plugins, and slash commands. Get the curated setup that actually fits how you build.",
      emoji: "🃏",
      status: :planning,
      mrr_usd: 0,
      path: nil,
      cta_label: "Get early access →",
      cta_source: "snapdeck_card"
    ),
    Service.new(
      name: "SnapTeam",
      tagline: "Real humans who've shipped what you're stuck on.",
      subline: "Not AI teammates. Not Discord noise. Match with vibe coders who solved your exact bug.",
      emoji: "👥",
      status: :planning,
      mrr_usd: 0,
      path: nil,
      cta_label: "Join the waitlist →",
      cta_source: "snapteam_card"
    )
  ].freeze

  def index
    @profile = PROFILE
    @services = SERVICES
    @bet = PUBLIC_BET
  end
end

