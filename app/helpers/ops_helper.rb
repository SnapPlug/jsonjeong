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

  INPUT = "w-full rounded-md border border-zinc-700 bg-zinc-800 px-2.5 py-1.5 text-[13px] text-zinc-100 placeholder:text-zinc-500 outline-none focus:border-zinc-500 focus:ring-2 focus:ring-zinc-600".freeze
  SMALL_CONTROL = "rounded-md border border-zinc-700 bg-zinc-800 px-2 py-1 text-xs text-zinc-200 outline-none hover:bg-zinc-700 focus:border-zinc-500".freeze
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
  def nav_link(label, path, dot: nil)
    active = current_page?(path)
    classes = active ? "bg-zinc-800 text-zinc-100" : "text-zinc-400 hover:bg-zinc-800/60 hover:text-zinc-100"
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

  def ok_dot(ok)
    ok.nil? ? "bg-zinc-600" : (ok ? "bg-green-500" : "bg-red-500")
  end
end
