module ApplicationHelper
  SITE_NAME = "Jason Jeong"
  SITE_TAGLINE = "아이디어 아카이브"
  SITE_DESCRIPTION = "하루 100달러를 벌어 보려고 AI와 검증한 아이디어를 실패한 것까지 전부 남깁니다. 몇 시간 걸렸고, 얼마 썼고, 얼마 벌었는지."
  SITE_PRODUCTION_URL = "https://jsonjeong.com".freeze
  # sitemap lastmod. config/ideas.yml을 고치면 같이 올린다.
  CONTENT_UPDATED_ON = "2026-10-19"
  GA4_ID = "G-51584NFH18"

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
    content_for?(:og_image) ? content_for(:og_image) : "#{site_url}/og-card.png?v=2"
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
          "inLanguage" => "ko",
          "publisher" => { "@id" => "#{SITE_PRODUCTION_URL}/#person" }
        },
        {
          "@type" => "Person",
          "@id" => "#{SITE_PRODUCTION_URL}/#person",
          "name" => SITE_NAME,
          "alternateName" => "Json Jeong",
          "url" => "#{SITE_PRODUCTION_URL}/",
          "image" => "#{SITE_PRODUCTION_URL}/icon.png",
          "jobTitle" => "SnapPlug 대표",
          "description" => "대한민국 제주에 사는 SnapPlug 대표. 하루 100달러를 벌어 보려고 AI와 아이디어를 하나씩 검증하고, 실패한 것까지 몇 시간 걸렸고 얼마 썼고 얼마 벌었는지 숫자로 남깁니다.",
          "address" => { "@type" => "PostalAddress", "addressLocality" => "Jeju", "addressCountry" => "KR" },
          "knowsAbout" => [ "AI agents", "Claude Code", "vibe coding", "idea validation", "side projects", "telecommunications", "Ruby on Rails" ],
          "worksFor" => { "@id" => "#{SITE_PRODUCTION_URL}/#org" },
          "sameAs" => [ "https://x.com/jasonjeongio", "https://www.threads.net/@snapplug.app", "https://github.com/SnapPlug" ]
        },
        {
          "@type" => "Organization",
          "@id" => "#{SITE_PRODUCTION_URL}/#org",
          "name" => "SnapPlug",
          "description" => "제조·유통 기업의 AI 자동화 컨설팅(AX)과 실용 도구를 만드는 회사. 현장에서 문제를 먼저 정의하고, 직원 저항 없이 안착하는 자동화를 설계합니다. 대표작으로 SnapDeck(바이브코딩 앱 보안 스캐너), SnapMusk, Snap Teleprompter가 있습니다.",
          "founder" => { "@id" => "#{SITE_PRODUCTION_URL}/#person" },
          "sameAs" => [ "https://github.com/SnapPlug", "https://www.threads.net/@snapplug.app" ]
        },
        {
          "@type" => "SoftwareApplication",
          "@id" => "#{SITE_PRODUCTION_URL}/#snapdeck",
          "name" => "SnapDeck",
          "applicationCategory" => "SecurityApplication",
          "operatingSystem" => "macOS",
          "description" => "AI로 만든 앱을 위한 데스크톱 보안 스캐너. 프로젝트 폴더를 끌어다 놓으면 SnapDeck이 노출된 키, 꺼진 RLS, 방치된 라우트를 쉬운 말로 찾아냅니다 — 로컬에서 실행되어 키가 컴퓨터를 떠나지 않습니다.",
          "url" => "https://snapdeck.jsonjeong.com",
          "offers" => { "@type" => "Offer", "price" => "0", "priceCurrency" => "USD" },
          "creator" => { "@id" => "#{SITE_PRODUCTION_URL}/#person" }
        },
        {
          "@type" => "SoftwareApplication",
          "name" => "SnapMusk",
          "applicationCategory" => "ProductivityApplication",
          "operatingSystem" => "macOS",
          "description" => "맥북 노치에 사는 AI 타임박싱 비서. '헤이 머스크' 웨이크워드, 온디바이스 음성인식(WhisperKit), Claude로 하루를 타임박싱합니다.",
          "url" => "https://github.com/SnapPlug/snapmusk",
          "creator" => { "@id" => "#{SITE_PRODUCTION_URL}/#person" }
        },
        {
          "@type" => "SoftwareApplication",
          "name" => "Snap Teleprompter",
          "applicationCategory" => "UtilitiesApplication",
          "operatingSystem" => "macOS",
          "description" => "맥북 노치 영역에 대본이 스크롤되는 텔레프롬프터 앱. 카메라를 보면서 자연스럽게 읽을 수 있습니다.",
          "url" => "https://github.com/SnapPlug/snap-teleprompter",
          "creator" => { "@id" => "#{SITE_PRODUCTION_URL}/#person" }
        },
        {
          "@type" => "SoftwareSourceCode",
          "name" => "Supabase 바이브코딩 가이드",
          "description" => "Claude Code(바이브코딩)로 Supabase 백엔드를 개발할 때 만나는 문제와 해결책 모음. 무료, 오픈소스.",
          "codeRepository" => "https://github.com/SnapPlug/supabase-vibe-coding-guide",
          "url" => "https://github.com/SnapPlug/supabase-vibe-coding-guide",
          "about" => "Supabase",
          "creator" => { "@id" => "#{SITE_PRODUCTION_URL}/#person" }
        }
      ]
    }
  end

  # <html lang>. 아이디어 화면은 컨트롤러가 정하고, 나머지는 한국어.
  def html_lang
    @html_lang || "ko"
  end

  def usd(amount)
    amount.zero? ? "$0" : number_to_currency(amount, unit: "$", precision: amount % 1 == 0 ? 0 : 2)
  end

  def idea_image(idea, **opts)
    image_tag "ideas/#{idea.slug}.jpg", alt: idea.title, width: 900, height: 800, **opts
  end

  def work_hours(hours)
    t("archive.hours_unit", hours: number_with_precision(hours, precision: 1, strip_insignificant_zeros: true))
  end

  # 메인: 아이디어 목록 / 회고글: 글 한 편. 사이트 공통 @graph(Person 등)에 더해 페이지별로 낸다.
  def ideas_structured_data(ideas)
    {
      "@context" => "https://schema.org",
      "@type" => "ItemList",
      "name" => t("archive.title"),
      "itemListElement" => ideas.each_with_index.map do |idea, i|
        { "@type" => "ListItem", "position" => i + 1, "name" => idea.title, "description" => idea.summary }
      end
    }
  end

  def retro_structured_data(idea)
    {
      "@context" => "https://schema.org",
      "@type" => "Article",
      "headline" => idea.title,
      "description" => idea.summary,
      "inLanguage" => html_lang,
      "url" => canonical_url,
      "image" => image_url("ideas/#{idea.slug}.jpg"),
      "datePublished" => idea.started_on.iso8601,
      "dateModified" => (idea.ended_on || Date.parse(CONTENT_UPDATED_ON)).iso8601,
      "author" => { "@id" => "#{SITE_PRODUCTION_URL}/#person" },
      "publisher" => { "@id" => "#{SITE_PRODUCTION_URL}/#person" }
    }
  end

  # 같은 페이지의 반대 언어 주소. hreflang과 언어 토글에 쓴다.
  def alternate_path(locale)
    url_for(locale: locale == :en ? "en" : nil, only_path: true)
  end
end
