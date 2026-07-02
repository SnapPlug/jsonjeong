module ApplicationHelper
  SITE_NAME = "Jason Jeong"
  SITE_TAGLINE = "현장에서 문제를 먼저 정의하는 AI 자동화 컨설턴트 · 제주"
  SITE_DESCRIPTION = "AI 자동화 회사 SnapPlug 대표. 공장과 사무실에 직접 가서 문제부터 정의하고, 답에 AI가 없으면 없다고 말합니다. 직원을 대체하지 않고 조직에 저항 없이 안착하는 자동화를 만듭니다. 제주에서."
  SITE_PRODUCTION_URL = "https://jsonjeong.com".freeze

  # AEO/GEO: question-answer content surfaced both on-page (collapsible) and as
  # FAQPage structured data. Single source so the two never drift.
  FAQS = [
    {
      q: "AI 자동화 컨설팅은 어떻게 진행하나요?",
      a: "'AI로 뭘 할까'가 아니라 '뭐가 문제인가'에서 시작합니다. 현장에 직접 가서 실무진의 이야기를 듣고 문제를 정의한 뒤, 답이 여럿이어도 되는 일은 AI로, 숫자가 정확해야 하는 일은 코드로, 판단이 필요한 일은 사람에게 남깁니다. 답에 AI가 없으면 없다고 말씀드립니다."
    },
    {
      q: "직원들이 자동화를 반대하면 어떻게 하나요?",
      a: "직원의 일을 대체하려는 자동화는 조용히 묻힙니다. 그래서 기존 업무는 최대한 건드리지 않고 반복 업무의 누수만 줄이는 방식으로 설계하고, 도입 후 직원의 일이 실제로 줄어드는지를 기준으로 삼습니다. 직원 저항을 줄이는 것까지가 컨설팅입니다."
    },
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
          "jobTitle" => "AI 자동화 컨설턴트 · SnapPlug 대표",
          "description" => "대한민국 제주의 AI 자동화 컨설턴트, SnapPlug 대표. 제조·유통 현장에 직접 가서 문제부터 정의하고, 직원을 대체하지 않고 조직에 저항 없이 안착하는 자동화를 설계합니다. 필요한 도구는 직접 만들어 공개합니다.",
          "address" => { "@type" => "PostalAddress", "addressLocality" => "Jeju", "addressCountry" => "KR" },
          "knowsAbout" => [ "AI agents", "AI automation", "application security", "vibe coding", "row-level security", "Supabase", "Ruby on Rails" ],
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
