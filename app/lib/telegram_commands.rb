# 텔레그램으로 들어온 명령 → 답장 글. 명령 셋뿐이다: 헬스체크(지금 체크) · 상태(마지막 결과) · 미수금.
module TelegramCommands
  include ActionView::Helpers::NumberHelper
  extend self

  def admin_chat_id = ENV["TELEGRAM_ADMIN_CHAT_ID"].to_s.strip

  # 명령을 받는 채팅: Jason 개인 대화 + 알림 채널(Overload). 답장은 명령이 온 곳으로 간다.
  def allowed_chat_ids = [ admin_chat_id, ENV["TELEGRAM_CHAT_ID"].to_s.strip ].reject(&:empty?)

  def run(text)
    case text.strip
    when %r{\A/?(check|헬스체크|체크)\z}i then check!
    when %r{\A/?(status|상태)\z}i then status
    when %r{\A/?(money|미수금|돈)\z}i then money
    when %r{\A/?(start|help|도움말)\z}i then help
    else "모르는 명령입니다.\n#{help}"
    end
  end

  def help
    "명령: 상태(마지막 결과, 5분마다 자동 체크) · 헬스체크(지금 새로 체크, 10–30초) · 미수금"
  end

  def check!
    HealthCheckJob.perform_now
    status(title: "✅ 지금 체크 완료")
  end

  def status(title: "📋 마지막 체크")
    logs = HealthLog.latest.includes(:client).to_a
    return ([ "#{title}", "체크 기록이 없습니다" ] + versions).join("\n") if logs.empty?
    failures = logs.reject(&:ok)
    lines = [ "#{title} · #{logs.size}개 중 실패 #{failures.size}" ]
    failures.each { |l| lines << "🔴 #{l.client.name} · #{HealthLog::LABELS[l.check_type]}: #{l.error}" }
    lines << "전부 정상" if failures.empty?
    last = logs.map(&:checked_at).max
    ago = ((Time.current - last) / 60).round
    lines << "#{last.in_time_zone('Seoul').strftime('%m/%d %H:%M')} 체크 · #{ago < 1 ? '방금' : "#{ago}분 전"}"
    (lines + versions).join("\n")
  end

  # 버전 현황. 프레임워크별로 "우리 버전 → 알려진 최신(같은 줄기)"과 고객사 이름. ⚠️는 같은 줄기 최신보다 낮음.
  FRAMEWORKS = { "nextjs" => "Next.js", "rails" => "Rails" }.freeze

  def versions
    lines = [ "", "📦 버전" ]
    FRAMEWORKS.each do |source, label|
      clients = Client.affected_by(source).where.not(stack_version: nil).order(:name)
      next if clients.empty?
      clients.group_by { |c| c.stack_version.split(".").first }.sort.reverse_each do |major, group|
        latest = latest_release(source, major)
        version = group.map(&:stack_version).uniq.join("/")
        mark = latest ? (Gem::Version.new(group.map(&:stack_version).min) < Gem::Version.new(latest) ? " ⚠️ 최신 #{latest}" : " ✅") : ""
        lines << "#{label} #{version}#{mark} — #{group.map(&:name).join(' · ')}"
      end
    end
    lines.size > 2 ? lines : []
  end

  # 플랫폼 소식에 기록된 그 줄기의 최신 릴리스(보안·마이너만 수집하므로 패치는 빠질 수 있다).
  def latest_release(source, major)
    PlatformEvent.where(source:, kind: "release").where("title LIKE ?", "v#{major}.%").recent.pick(:title)&.delete_prefix("v")
  end

  def money
    unpaid = Payment.unpaid.includes(contract: :client).order(:due_on)
    return "💰 미수금 없음" if unpaid.empty?
    lines = [ "💰 미수금 #{won(unpaid.sum(&:amount))} · #{unpaid.size}건" ]
    unpaid.each do |p|
      overdue = (Date.current - p.due_on).to_i
      lines << "#{overdue > 0 ? '⚠️' : '•'} #{p.contract.client.name} #{OpsHelper::PAYMENT_KINDS[p.kind]} #{won(p.amount)} · 마감 #{p.due_on.strftime('%m/%d')}#{overdue > 0 ? " (+#{overdue}일)" : ''}"
    end
    lines.join("\n")
  end

  def won(amount) = "#{number_with_delimiter(amount)}원"
end
