module OpsHelper
  PAYMENT_KINDS = { "deposit" => "계약금", "interim" => "중도금", "balance" => "잔금" }.freeze
  PAYMENT_STATUSES = { "pending" => "미수금", "paid" => "수금완료", "overdue" => "연체", "cancelled" => "취소" }.freeze
  CONTRACT_STATUSES = { "in_progress" => "진행중", "completed" => "완료", "overdue" => "연체", "cancelled" => "취소" }.freeze
  CLIENT_STATUSES = { "active" => "진행중", "paused" => "일시중지", "completed" => "완료" }.freeze
  CLIENT_KINDS = { "vercel_supabase" => "Vercel + Supabase", "rails" => "Rails", "channeltalk" => "채널톡", "other" => "기타" }.freeze

  # 상태 색은 세 가지 뜻만 쓴다: 초록=끝남/정상, 노랑=기다림, 빨강=문제. 나머지는 회색.
  GREEN  = "border-green-500/20 bg-green-500/10 text-green-400"
  YELLOW = "border-yellow-500/20 bg-yellow-500/10 text-yellow-400"
  BLUE   = "border-blue-500/20 bg-blue-500/10 text-blue-400"
  RED    = "border-red-500/20 bg-red-500/10 text-red-400"
  GRAY   = "border-zinc-700 bg-zinc-800 text-zinc-500"
  STATUS_COLORS = {
    "paid" => GREEN, "completed" => GREEN,
    "pending" => YELLOW,
    "in_progress" => BLUE, "active" => BLUE,
    "overdue" => RED,
    "cancelled" => GRAY, "paused" => GRAY
  }.freeze

  # iOS는 16px 미만 입력칸에 초점이 가면 화면을 확대한다. 그래서 md 미만은 text-base.
  INPUT = "w-full min-w-0 rounded-md border border-zinc-700 bg-zinc-800 px-2.5 py-1.5 text-base text-zinc-100 md:text-[13px] placeholder:text-zinc-500 outline-none focus:border-zinc-500 focus:ring-2 focus:ring-zinc-600".freeze
  SMALL_CONTROL = "rounded-md border border-zinc-700 bg-zinc-800 px-2 py-1.5 text-base text-zinc-200 md:py-1 md:text-xs outline-none hover:bg-zinc-700 focus:border-zinc-500".freeze
  PRIMARY_BUTTON = "rounded-md bg-zinc-100 px-3 py-1.5 text-[13px] font-medium text-zinc-900 hover:bg-white cursor-pointer".freeze
  SECONDARY_BUTTON = "rounded-md border border-zinc-700 bg-zinc-800 px-2.5 py-1 text-xs text-zinc-200 hover:bg-zinc-700 cursor-pointer".freeze

  def won(amount)
    "#{number_with_delimiter(amount)}원"
  end

  def kst(time)
    time&.in_time_zone("Seoul")&.strftime("%m/%d %H:%M")
  end

  def days_overdue(date)
    (Date.current - date).to_i
  end

  def status_badge(status, labels)
    tag.span(labels.fetch(status, status), class: "inline-block rounded border px-1.5 py-0.5 text-xs font-medium #{STATUS_COLORS[status]}")
  end

  # 상태 변경 셀렉트 + 버튼. JS 없이 동작한다.
  def status_form(url, field, current, labels)
    form_with url:, method: :patch, class: "inline-flex items-center gap-1" do
      safe_join([
        select_tag(field, options_for_select(labels.map { |k, v| [ v, k ] }, current), class: "#{SMALL_CONTROL} cursor-pointer"),
        submit_tag("변경", class: SMALL_CONTROL + " cursor-pointer")
      ])
    end
  end

  # 사이드바 항목. 현재 페이지면 밝게.
  def nav_link(label, path, dot: nil, dim: false)
    active = current_page?(path)
    classes = if active then "bg-zinc-800 text-zinc-100"
    elsif dim then "text-zinc-600 hover:bg-zinc-800/60 hover:text-zinc-300"
    else "text-zinc-400 hover:bg-zinc-800/60 hover:text-zinc-100"
    end
    link_to path, class: "flex items-center gap-2 rounded-md px-2 py-1.5 text-[13px] #{classes}" do
      safe_join([ (tag.span(class: "h-1.5 w-1.5 shrink-0 rounded-full #{dot}") if dot), tag.span(label, class: "truncate") ].compact)
    end
  end

  # 사이드바 점 색: 감시 안 하면 없음, 체크 전이면 회색, 하나라도 실패면 빨강, 아니면 초록.
  def health_dot(client)
    return nil if client.checks.empty?
    logs = sidebar_health[client.id]
    return "bg-zinc-600" if logs.blank?
    logs.any? { |log| !log.ok } ? "bg-red-500" : "bg-green-500"
  end

  # 서비스 상태 배지 아이콘. Vercel은 lobehub 아이콘, Supabase는 공식 로고(simple-icons), URL은 지구본.
  CHECK_ICONS = {
    "url" => '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" class="h-3.5 w-3.5 text-zinc-400"><circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18"/></svg>',
    "vercel" => '<svg viewBox="0 0 24 24" fill="currentColor" class="h-3.5 w-3.5 text-zinc-100"><path d="M12 0l12 20.785H0L12 0z"/></svg>',
    "supabase" => '<svg viewBox="0 0 24 24" fill="#3ECF8E" class="h-3.5 w-3.5"><path d="M11.9 1.036c-.015-.986-1.26-1.41-1.874-.637L.764 12.05C-.33 13.427.65 15.455 2.409 15.455h9.579l.113 7.51c.014.985 1.259 1.408 1.873.636l9.262-11.653c1.093-1.375.113-3.403-1.645-3.403h-9.642z"/></svg>'
  }.freeze

  # URL 체크는 응답하는 것이 고객사마다 다르다: Rails 서버 · Cloudflare Workers · Next.js(Vercel). 그걸 아이콘으로 보여준다.
  # Vercel 배지(배포 상태)와 Supabase 배지(DB)는 따로 있으니 URL 배지는 "앱"을 말한다.
  URL_ICONS = {
    "rails" => [ "Rails", '<svg viewBox="0 0 24 24" fill="#D30001" class="h-3.5 w-3.5"><path d="M.741 19.365h8.36s-1.598-7.291 3.693-10.243l.134-.066c1.286-.637 4.907-2.431 10.702 1.854.19-.159.37-.286.37-.286s-5.503-5.492-11.63-4.878c-3.079.275-6.867 3.079-9.09 6.783C1.058 16.233.741 19.365.741 19.365Zm8.804-.783a10.682 10.682 0 0 1-.127-1.333l1.143.412c.063.498.159.963.254 1.376l-1.27-.455Zm-7.799-4.317L.529 13.82c-.201.455-.423.984-.529 1.27l1.217.444c.137-.359.36-.878.529-1.269Zm7.831.296.857.677c.042-.413.116-.825.222-1.238l-.762-.603c-.137.391-.233.783-.317 1.164Zm2.042-2.646-.508-.762c.191-.243.413-.486.656-.709l.476.72a5.958 5.958 0 0 0-.624.751ZM4.19 8.878l.752.656c-.254.265-.498.551-.72.836l-.815-.698c.244-.265.508-.529.783-.794Zm9.799 1.027-.243-.73c.265-.117.571-.233.931-.339l.233.698a6.82 6.82 0 0 0-.921.371Zm3.122-.656.042-.667c.339.021.688.064 1.048.138l-.042.656a5.859 5.859 0 0 0-1.048-.127ZM8.942 6.392l-.476-.731c-.265.138-.54.286-.826.455l.487.741c.275-.169.54-.328.815-.465Zm9.217-.053.042-.709c-.095-.053-.36-.18-1.026-.371l-.043.699c.349.116.688.243 1.027.381ZM13.238 5.28h.106l-.212-.645c-.328 0-.666.021-1.016.063l.201.625a8.87 8.87 0 0 1 .921-.043Z"/></svg>' ],
    "cloudflare" => [ "Cloudflare Workers", '<svg viewBox="0 0 24 24" fill="#F38020" class="h-3.5 w-3.5"><path d="M16.493 17.4c.135-.52.08-.983-.161-1.338-.215-.328-.592-.519-1.05-.519l-8.663-.109a.148.148 0 01-.135-.082c-.027-.054-.027-.109-.027-.163.027-.082.108-.164.189-.164l8.744-.11c1.05-.054 2.153-.9 2.556-1.937l.511-1.31c.027-.055.027-.11.027-.164C17.92 8.91 15.66 7 12.942 7c-2.503 0-4.628 1.638-5.381 3.903a2.432 2.432 0 00-1.803-.491c-1.21.109-2.153 1.092-2.287 2.32-.027.328 0 .628.054.9C1.56 13.688 0 15.326 0 17.319c0 .19.027.355.027.545 0 .082.08.137.161.137h15.983c.08 0 .188-.055.215-.164l.107-.437"/><path d="M19.238 11.75h-.242c-.054 0-.108.054-.135.109l-.35 1.2c-.134.52-.08.983.162 1.338.215.328.592.518 1.05.518l1.855.11c.054 0 .108.027.135.082.027.054.027.109.027.163-.027.082-.108.164-.188.164l-1.91.11c-1.05.054-2.153.9-2.557 1.937l-.134.355c-.027.055.026.137.107.137h6.592c.081 0 .162-.055.162-.137.107-.41.188-.846.188-1.31-.027-2.62-2.153-4.777-4.762-4.777"/></svg>' ],
    "nextjs" => [ "Next.js", '<svg viewBox="0 0 24 24" fill="currentColor" class="h-3.5 w-3.5 text-zinc-100"><path d="M18.665 21.978C16.758 23.255 14.465 24 12 24 5.377 24 0 18.623 0 12S5.377 0 12 0s12 5.377 12 12c0 3.583-1.574 6.801-4.067 9.001L9.219 7.2H7.2v9.596h1.615V9.251l9.85 12.727Zm-3.332-8.533 1.6 2.061V7.2h-1.6v6.245Z"/></svg>' ],
    "url" => [ "URL", CHECK_ICONS["url"] ]
  }.freeze

  # 플랫폼 소식 한 줄의 로고. 서비스 상태 배지와 같은 그림을 쓴다.
  def platform_icon(source)
    svg = case source
    when "vercel", "supabase" then CHECK_ICONS[source]
    when "nextjs", "rails", "cloudflare" then URL_ICONS.fetch(source).last
    end
    svg&.html_safe # rubocop:disable Rails/OutputSafety -- 상수 문자열
  end

  # 배지 하나의 [라벨, 아이콘]. URL이면 고객사가 무엇으로 응답하는지로 고른다.
  def check_badge(client, check)
    return [ HealthLog::LABELS[check], CHECK_ICONS.fetch(check).html_safe ] unless check == "url" # rubocop:disable Rails/OutputSafety -- 상수 문자열
    key = if client.health_url.to_s.include?("workers.dev") then "cloudflare"
    elsif client.kind == "rails" then "rails"
    elsif client.kind == "vercel_supabase" then "nextjs"
    else "url"
    end
    label, svg = URL_ICONS.fetch(key)
    [ label, svg.html_safe ] # rubocop:disable Rails/OutputSafety -- 상수 문자열
  end

  def ok_dot(ok)
    ok.nil? ? "bg-zinc-600" : (ok ? "bg-green-500" : "bg-red-500")
  end
end
