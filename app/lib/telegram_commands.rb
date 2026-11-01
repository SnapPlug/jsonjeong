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
    "명령: 헬스체크(지금 전부 체크) · 상태(마지막 결과) · 미수금"
  end

  def check!
    HealthCheckJob.perform_now
    status(title: "✅ 지금 체크 완료")
  end

  def status(title: "📋 마지막 체크")
    logs = HealthLog.latest.includes(:client).to_a
    return "#{title}\n체크 기록이 없습니다" if logs.empty?
    failures = logs.reject(&:ok)
    lines = [ "#{title} · #{logs.size}개 중 실패 #{failures.size}" ]
    failures.each { |l| lines << "🔴 #{l.client.name} · #{HealthLog::LABELS[l.check_type]}: #{l.error}" }
    lines << "전부 정상" if failures.empty?
    lines << "마지막 #{logs.map(&:checked_at).max.in_time_zone('Seoul').strftime('%m/%d %H:%M')}"
    lines.join("\n")
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
