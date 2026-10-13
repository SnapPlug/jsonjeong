# 5분마다 (config/recurring.yml). 감시 대상 고객사의 체크를 전부 돌리고 기록하고, 판정에 따라 텔레그램.
class HealthCheckJob < ApplicationJob
  queue_as :default

  def perform
    checked_at = Time.current

    Client.monitored.find_each do |client|
      client.checks.each do |check_type|
        previous = client.health_logs.where(check_type:).order(:checked_at).last(2).map(&:ok)
        result = HealthCheck.run(client, check_type)
        client.health_logs.create!(check_type:, ok: result.ok, status_code: result.status_code,
                                   ms: result.ms, error: result.error, checked_at:)
        notify(client, check_type, HealthLog.transition(previous, result.ok), result)
      end
    end

    HealthCheck.heartbeat
  end

  private
    def notify(client, check_type, transition, result)
      label = "#{client.name} · #{HealthLog::LABELS[check_type]}"
      case transition
      when :down then Telegram.send_message("🔴 #{label}\n#{result.error}")
      when :up then Telegram.send_message("🟢 #{label} 복구")
      end
    end
end
