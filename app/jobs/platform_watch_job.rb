# 한 시간마다 (config/recurring.yml). 새 소식은 저장하고, 최근 3일 안의 것만 텔레그램으로 알린다.
# 3일 규칙 덕에 처음 돌 때 묵은 소식으로 채널이 넘치지 않는다. 장애는 해결될 때 한 번 더 알린다.
class PlatformWatchJob < ApplicationJob
  queue_as :default
  FRESH = 3.days

  def perform
    PlatformWatch.fetch_all.each do |event|
      record = PlatformEvent.find_or_initialize_by(source: event.source, external_id: event.external_id)
      was_new = record.new_record?
      resolved_now = !was_new && !record.resolved? && event.status == "resolved"
      record.assign_attributes(event.to_h.except(:source, :external_id))
      record.save!

      next unless event.happened_at > FRESH.ago && (was_new || resolved_now)
      Telegram.send_message(message(record))
      record.update!(notified_at: Time.current)
    end
  end

  private
    def message(e)
      if e.kind == "incident"
        "#{e.resolved? ? '🟢' : '🟠'} #{e.label} 장애#{e.resolved? ? ' 해결' : ''}: #{e.title}#{e.resolved? ? '' : " (#{e.status})"}\n#{e.url}"
      else
        "🆕 #{e.label} #{e.title}#{e.status == 'security' ? ' (보안)' : ''}\n#{e.url}"
      end
    end
end
