require "test_helper"

class PlatformWatchJobTest < ActiveJob::TestCase
  def event(**attrs)
    PlatformWatch::Event.new(**{ source: "vercel", kind: "incident", external_id: "abc", title: "빌드 지연",
                                 status: "investigating", url: "https://x", happened_at: 1.hour.ago }.merge(attrs))
  end

  def run_with(events)
    messages = []
    stubbing(Telegram, :send_message, ->(text) { messages << text }) do
      stubbing(PlatformWatch, :fetch_all, events) { PlatformWatchJob.perform_now }
    end
    messages
  end

  test "새 장애는 알리고, 같은 장애는 다시 알리지 않고, 해결되면 한 번 더 알린다" do
    assert_equal [ "🟠 Vercel 장애: 빌드 지연 (investigating)\n우리 1곳: 에이스상사\nhttps://x" ], run_with([ event ])
    assert_empty run_with([ event(status: "monitoring") ])
    assert_equal [ "🟢 Vercel 장애 해결: 빌드 지연\n우리 1곳: 에이스상사\nhttps://x" ], run_with([ event(status: "resolved") ])
    assert_equal 1, PlatformEvent.count
  end

  test "알림에 우리 고객사 현황이 붙는다: 장애는 이름, 릴리스는 버전 비교" do
    clients(:acme).update!(stack_version: "16.2.6")
    assert_equal [ "🟠 Vercel 장애: 빌드 지연 (investigating)\n우리 1곳: 에이스상사\nhttps://x" ], run_with([ event ])
    release = event(source: "nextjs", kind: "release", external_id: "v16.4.1", title: "v16.4.1", status: "security")
    assert_equal [ "🆕 Next.js v16.4.1 (보안)\n우리 1곳: 에이스상사 16.2.6 ⚠️\nhttps://x" ], run_with([ release ])
  end

  test "묵은 소식은 저장만 하고 알리지 않는다" do
    assert_empty run_with([ event(source: "rails", kind: "release", external_id: "v8.1.0", title: "v8.1.0", status: "minor", happened_at: 30.days.ago) ])
    assert_equal 1, PlatformEvent.count
  end
end
