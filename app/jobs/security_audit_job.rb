# 매주 월 09:00 KST (config/recurring.yml). 문제가 없어도 한 줄 보낸다 — 점검이 돌았다는 증거다.
class SecurityAuditJob < ApplicationJob
  queue_as :default

  def perform
    issues = SecurityAudit.run
    text = if issues.empty?
      "🛡️ 주간 보안 점검: 이상 없음"
    else
      "🛡️ 주간 보안 점검: #{issues.size}건\n#{issues.map { |issue| "• #{issue}" }.join("\n")}"
    end
    Telegram.send_message(text)
  end
end
