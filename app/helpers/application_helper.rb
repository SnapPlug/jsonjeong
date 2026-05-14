module ApplicationHelper
  SITE_NAME = "Jason Jeong"
  SITE_TAGLINE = "Vibe Coding Services"
  SITE_DESCRIPTION = "Indie SaaS shipped fast from a Korean island. Solo dev, Rails 8, AI-assisted."
  SITE_PRODUCTION_URL = "https://jsonjeong.com".freeze

  def site_url
    Rails.env.production? ? SITE_PRODUCTION_URL : request.base_url
  end

  def page_title
    base = content_for?(:title) ? content_for(:title) : SITE_TAGLINE
    "#{base} — #{SITE_NAME}"
  end

  def page_description
    content_for?(:description) ? content_for(:description) : SITE_DESCRIPTION
  end

  def canonical_url
    "#{site_url}#{request.path}"
  end

  def og_image_url
    "#{site_url}#{asset_path('profile@2x.jpeg')}"
  end

  # ASCII progress bar for the Public Bet box. 10 cells, ▰ filled / ▱ empty.
  def bet_progress_bar(current, goal, cells: 10)
    pct = goal.to_f.positive? ? (current.to_f / goal * 100) : 0.0
    pct = pct.clamp(0, 100)
    filled = (pct / 100.0 * cells).round
    empty = cells - filled
    ("▰" * filled) + ("▱" * empty)
  end

  def bet_progress_pct(current, goal)
    return 0 unless goal.to_f.positive?
    ((current.to_f / goal) * 100).round
  end
end
