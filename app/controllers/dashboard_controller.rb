class DashboardController < ApplicationController
  allow_unauthenticated_access only: :index

  # Service status drives card badge color + CTA copy.
  # :planning → not started · :building → in progress · :shipped → live with paying users
  Service = Data.define(:name, :tagline, :subline, :emoji, :status, :mrr_usd, :path, :cta_label, :cta_source, :trust, :concept) do
    def initialize(trust: nil, concept: nil, **) = super
  end

  PROFILE = {
    name: "Json Jeong",
    location: "Jeju, South Korea",
    revenue: "$0/month",
    quote: "I shipped my first apps wide open. Now I'm building the safety net — $0 → $1K MRR, in public.",
    newsletter_count: "1",
    newsletter_name: "Snap to It",
    newsletter_tagline: "What I shipped, what broke, and the security holes I keep finding. No fluff.",
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
    rules: "No ads, no audience, no agency. Miss it and quote-tweet me forever."
  }.freeze

  SERVICES = [
    Service.new(
      name: "SnapDeck",
      tagline: "The security net for the apps you built with AI.",
      subline: "RLS left wide open, keys exposed in the bundle, routes anyone can hit — SnapDeck catches it in plain English, before someone else does.",
      trust: "Runs on your machine. Your keys never leave.",
      concept: "Security scanner",
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
