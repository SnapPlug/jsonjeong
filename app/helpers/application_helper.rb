module ApplicationHelper
  SITE_NAME = "Jason Jeong"
  SITE_TAGLINE = "Security for vibe-coded apps"
  SITE_DESCRIPTION = "I help vibe coders secure the apps AI built — exposed keys, disabled RLS, unguarded routes, caught in plain English. Solo dev building in public from Jeju."
  SITE_PRODUCTION_URL = "https://jsonjeong.com".freeze

  # AEO/GEO: question-answer content surfaced both on-page (collapsible) and as
  # FAQPage structured data. Single source so the two never drift.
  FAQS = [
    {
      q: "How do I know if my vibe-coded app is secure?",
      a: "Most apps built with AI ship with the same handful of holes: row-level security left disabled, API keys bundled into the client, and routes with no auth check. A scanner like SnapDeck reads your project folder locally and flags them in plain English, before someone else finds them."
    },
    {
      q: "What are the most common security mistakes in AI-generated apps?",
      a: "Disabled or misconfigured row-level security (anyone can read every user's row), secret keys exposed in the client bundle, admin routes with no authentication, and overly permissive CORS. These rarely show up in the AI's own code review because they live in config and infrastructure, not the code it wrote."
    },
    {
      q: "Does SnapDeck send my code to the cloud?",
      a: "No. SnapDeck runs entirely on your machine. Your source code and your API keys never leave your computer."
    },
    {
      q: "Can a non-technical founder use it?",
      a: "Yes. It is built for people who shipped with AI and don't read code. You drop your project folder, get the findings in plain English, and let it fix them for you."
    },
    {
      q: "What is vibe coding?",
      a: "Vibe coding is building software mostly by prompting AI tools rather than writing the code yourself. The speed is incredible; the security usually isn't. Closing that gap is the whole point of what I'm building."
    }
  ].freeze

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
    "#{site_url}/og-card.png"
  end

  # Site-wide JSON-LD entities (WebSite + Person + SoftwareApplication).
  # Emitted on every page via shared/_structured_data. Returns a schema.org @graph.
  def site_structured_data
    {
      "@context" => "https://schema.org",
      "@graph" => [
        {
          "@type" => "WebSite",
          "@id" => "#{SITE_PRODUCTION_URL}/#website",
          "name" => SITE_NAME,
          "url" => "#{SITE_PRODUCTION_URL}/",
          "description" => SITE_DESCRIPTION,
          "inLanguage" => "en",
          "publisher" => { "@id" => "#{SITE_PRODUCTION_URL}/#person" }
        },
        {
          "@type" => "Person",
          "@id" => "#{SITE_PRODUCTION_URL}/#person",
          "name" => SITE_NAME,
          "alternateName" => "Json Jeong",
          "url" => "#{SITE_PRODUCTION_URL}/",
          "image" => "#{SITE_PRODUCTION_URL}/icon.png",
          "jobTitle" => "Indie developer & app security builder",
          "description" => "Solo developer in Jeju, South Korea, building tools that help vibe coders secure the apps they shipped with AI.",
          "address" => { "@type" => "PostalAddress", "addressLocality" => "Jeju", "addressCountry" => "KR" },
          "knowsAbout" => ["application security", "vibe coding", "Ruby on Rails", "row-level security", "Supabase"],
          "sameAs" => ["https://x.com/jasonjeongio", "https://www.threads.net/@snapplug.app"]
        },
        {
          "@type" => "SoftwareApplication",
          "@id" => "#{SITE_PRODUCTION_URL}/#snapdeck",
          "name" => "SnapDeck",
          "applicationCategory" => "SecurityApplication",
          "operatingSystem" => "macOS",
          "description" => "A desktop security scanner for apps built with AI. Drop your project folder and SnapDeck finds exposed keys, disabled row-level security, and unguarded routes in plain English — locally, so your keys never leave your machine.",
          "offers" => { "@type" => "Offer", "price" => "0", "priceCurrency" => "USD" },
          "creator" => { "@id" => "#{SITE_PRODUCTION_URL}/#person" }
        }
      ]
    }
  end

  # FAQPage JSON-LD built from FAQS. Page-scoped (rendered only where the
  # matching questions are visible on the page).
  def faq_structured_data(faqs = FAQS)
    {
      "@context" => "https://schema.org",
      "@type" => "FAQPage",
      "mainEntity" => faqs.map do |item|
        {
          "@type" => "Question",
          "name" => item[:q],
          "acceptedAnswer" => { "@type" => "Answer", "text" => item[:a] }
        }
      end
    }
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
