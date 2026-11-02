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
      head = if e.kind == "incident"
        "#{e.resolved? ? '🟢' : '🟠'} #{e.label} 장애#{e.resolved? ? ' 해결' : ''}: #{e.title}#{e.resolved? ? '' : " (#{e.status})"}"
      else
        "🆕 #{e.label} #{e.title}#{e.status == 'security' ? ' (보안)' : ''}"
      end
      [ head, ours(e), e.url ].compact.join("\n")
    end

    # 우리 고객사 현황 한 줄. 장애면 이름만, 릴리스면 버전과 ⚠️/✅.
    def ours(e)
      clients = Client.affected_by(e.source).order(:name)
      return nil if clients.empty?
      return regional(e, clients) if e.source == "supabase" && e.regions.any?
      list = e.kind == "release" ? clients.map { |c| c.version_mark(e.title) } : clients.map(&:name)
      "우리 #{clients.size}곳: #{list.join(' · ')}"
    end

    # 장애 리전과 우리 리전 비교. 리전을 모르는 고객사는 영향 후보로 둔다.
    def regional(e, clients)
      hit, miss = clients.partition { |c| c.supabase_region.nil? || e.regions.include?(c.supabase_region) }
      named = ->(list) { list.map { |c| "#{c.name} #{c.supabase_region || '리전?'}" }.join(" · ") }
      hit.empty? ? "우리 리전 아님: #{named.call(miss)}" : "우리 #{hit.size}곳: #{named.call(hit)}"
    end
end
