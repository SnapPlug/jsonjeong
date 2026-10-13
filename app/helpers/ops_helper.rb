module OpsHelper
  PAYMENT_KINDS = { "deposit" => "계약금", "interim" => "중도금", "balance" => "잔금" }.freeze
  PAYMENT_STATUSES = { "pending" => "미수금", "paid" => "수금완료", "overdue" => "연체", "cancelled" => "취소" }.freeze
  CONTRACT_STATUSES = { "in_progress" => "진행중", "completed" => "완료", "overdue" => "연체", "cancelled" => "취소" }.freeze
  CLIENT_STATUSES = { "active" => "진행중", "paused" => "일시중지", "completed" => "완료" }.freeze
  CLIENT_KINDS = { "vercel_supabase" => "Vercel + Supabase", "rails" => "Rails", "channeltalk" => "채널톡", "other" => "기타" }.freeze

  STATUS_COLORS = {
    "paid" => "bg-green-100 text-green-800", "completed" => "bg-green-100 text-green-800",
    "pending" => "bg-yellow-100 text-yellow-800", "in_progress" => "bg-blue-100 text-blue-800", "active" => "bg-blue-100 text-blue-800",
    "overdue" => "bg-red-100 text-red-800",
    "cancelled" => "bg-gray-100 text-gray-500", "paused" => "bg-gray-100 text-gray-500"
  }.freeze

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
    tag.span(labels.fetch(status, status), class: "inline-block rounded px-1.5 py-0.5 text-xs font-medium #{STATUS_COLORS[status]}")
  end

  # 상태 변경 셀렉트 + 버튼. JS 없이 동작한다.
  def status_form(url, field, current, labels)
    form_with url:, method: :patch, class: "inline-flex items-center gap-1" do
      safe_join([
        select_tag(field, options_for_select(labels.map { |k, v| [ v, k ] }, current), class: "rounded border border-gray-300 bg-white px-1.5 py-0.5 text-xs"),
        submit_tag("변경", class: "rounded border border-gray-300 bg-white px-1.5 py-0.5 text-xs cursor-pointer hover:bg-gray-50")
      ])
    end
  end
end
