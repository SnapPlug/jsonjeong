# 한 시간마다 (config/recurring.yml). 소식은 전부 저장해 대시보드에 두고, 우리가 할 일이 있는 것만 텔레그램으로 알린다.
# 장애: 우리가 쓰는 기능과 리전에 닿고 아직 진행 중일 때. 알린 장애만 해결도 알린다.
# 릴리스: 보안은 올려야 할 고객사가 있을 때. 마이너·메이저는 줄기를 올려야 할 고객사가 있을 때(/security-patch §0).
# 3일 규칙 덕에 처음 돌 때 묵은 소식으로 채널이 넘치지 않는다.
class PlatformWatchJob < ApplicationJob
  queue_as :default
  FRESH = 3.days
  ACTION = /⚠️|⬆️| \?$/  # 올리거나, 줄기를 올리거나, 버전을 모르거나
  STEM = /⬆️/

  def perform
    PlatformWatch.fetch_all.each do |event|
      record = PlatformEvent.find_or_initialize_by(source: event.source, external_id: event.external_id)
      was_new = record.new_record?
      resolved_now = !was_new && !record.resolved? && event.status == "resolved"
      record.assign_attributes(event.to_h.except(:source, :external_id))
      record.save!

      next unless event.happened_at > FRESH.ago
      next unless resolved_now ? record.notified_at : (was_new && alert?(record))
      Telegram.send_message(message(record))
      record.update!(notified_at: Time.current)
    end
  end

  private
    def alert?(e)
      clients = Client.affected_by(e.source)
      return false if clients.empty?
      return !e.resolved? && e.touches_us? && (e.regions.empty? || e.source != "supabase" || regional_hits(e, clients).any?) if e.kind == "incident"
      (e.status == "security" ? ACTION : STEM).then { |mark| clients.any? { |c| c.version_mark(e.title).match?(mark) } }
    end

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
      list = e.kind == "release" ? clients.map { |c| c.version_mark(e.title) }.grep(ACTION) : clients.map(&:name)
      "우리 #{list.size}곳: #{list.join(' · ')}"
    end

    # 장애 리전에 있는 고객사. 리전을 모르는 고객사는 영향 후보로 둔다.
    def regional_hits(e, clients)
      clients.select { |c| c.supabase_region.nil? || e.regions.include?(c.supabase_region) }
    end

    def regional(e, clients)
      hits = regional_hits(e, clients)
      "우리 #{hits.size}곳: #{hits.map { |c| "#{c.name} #{c.supabase_region || '리전?'}" }.join(' · ')}"
    end
end
