require "test_helper"

class TelegramCommandsTest < ActiveSupport::TestCase
  test "상태: 실패만 줄로, 없으면 전부 정상" do
    clients(:acme).health_logs.create!(check_type: "url", ok: true, checked_at: Time.current)
    assert_match(/실패 0\n전부 정상/, TelegramCommands.run("상태"))
    clients(:acme).health_logs.create!(check_type: "vercel", ok: false, error: "HTTP 503", checked_at: Time.current)
    out = TelegramCommands.run("/status")
    assert_match(/실패 1/, out)
    assert_match(/🔴 에이스상사 · Vercel: HTTP 503/, out)
  end

  test "미수금: 연체는 ⚠️와 +일수" do
    out = TelegramCommands.run("미수금")
    assert_match(/💰 미수금/, out)
  end

  test "모르는 명령은 도움말" do
    assert_match(/모르는 명령/, TelegramCommands.run("안녕"))
  end
end
