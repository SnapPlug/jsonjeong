module ApplicationHelper
  SITE_NAME = "Jason Jeong"
  SITE_TAGLINE = "AI 팀원을 만드는 바이브코더 · 제주"
  SITE_DESCRIPTION = "바이브코더이자 AI 자동화 회사 대표. AI 팀원을 만들어 제품으로 내놓고, 세상에 도움 되는 아이디어를 계속 출시하며 공개적으로 수익화합니다. 제주에서."
  SITE_PRODUCTION_URL = "https://jsonjeong.com".freeze

  # AEO/GEO: question-answer content surfaced both on-page (collapsible) and as
  # FAQPage structured data. Single source so the two never drift.
  FAQS = [
    {
      q: "내 바이브코딩 앱이 안전한지 어떻게 알 수 있나요?",
      a: "AI로 만든 앱은 대부분 똑같은 구멍 몇 개를 안고 출시됩니다: 꺼진 RLS(행 수준 보안), 클라이언트에 박힌 API 키, 인증 체크 없는 라우트. SnapDeck 같은 스캐너가 프로젝트 폴더를 로컬에서 읽어, 누가 먼저 찾기 전에 쉬운 말로 알려줍니다."
    },
    {
      q: "AI가 만든 앱에서 가장 흔한 보안 실수는 무엇인가요?",
      a: "꺼지거나 잘못 설정된 RLS(아무나 모든 사용자의 행을 읽음), 클라이언트 번들에 노출된 시크릿 키, 인증 없는 관리자 라우트, 너무 느슨한 CORS. 이것들은 AI가 짠 코드가 아니라 설정·인프라에 있어서 AI 자체 코드 리뷰에는 거의 안 잡힙니다."
    },
    {
      q: "SnapDeck이 제 코드를 클라우드로 보내나요?",
      a: "아니요. SnapDeck은 전적으로 내 컴퓨터에서 실행됩니다. 소스 코드와 API 키는 절대 컴퓨터를 떠나지 않습니다."
    },
    {
      q: "비개발자 창업자도 쓸 수 있나요?",
      a: "네. 코드를 못 읽어도 AI로 출시한 사람을 위해 만들었습니다. 프로젝트 폴더를 끌어다 놓으면 쉬운 말로 진단해주고, 대신 고쳐주기까지 합니다."
    },
    {
      q: "바이브코딩이 뭔가요?",
      a: "바이브코딩은 직접 코드를 쓰기보다 AI 도구에 지시해서 소프트웨어를 만드는 방식입니다. 속도는 엄청나지만 보안은 대개 그렇지 않죠. 그 간극을 메우는 게 제가 만드는 것의 핵심입니다."
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
    "#{site_url}/og-card.png?v=2"
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
          "jobTitle" => "AI 팀원을 만드는 바이브코더 · AI 자동화 회사 대표",
          "description" => "대한민국 제주의 1인 개발자이자 AI 자동화 회사 대표. AI 팀원을 만들어 제품으로 내놓고, 세상에 도움 되는 아이디어를 계속 출시하며 공개적으로 수익화합니다.",
          "address" => { "@type" => "PostalAddress", "addressLocality" => "Jeju", "addressCountry" => "KR" },
          "knowsAbout" => [ "AI agents", "AI automation", "application security", "vibe coding", "row-level security", "Supabase", "Ruby on Rails" ],
          "sameAs" => [ "https://x.com/jasonjeongio", "https://www.threads.net/@snapplug.app", "https://github.com/SnapPlug" ]
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
end
