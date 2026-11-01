require "test_helper"

class Ops::TelegramControllerTest < ActionDispatch::IntegrationTest
  setup do
    ENV["TELEGRAM_WEBHOOK_SECRET"] = "s3cret"
    ENV["TELEGRAM_ADMIN_CHAT_ID"] = "777"
    ENV["TELEGRAM_CHAT_ID"] = "-100555"
    host! "ops.example.com"
  end

  teardown { %w[TELEGRAM_WEBHOOK_SECRET TELEGRAM_ADMIN_CHAT_ID TELEGRAM_CHAT_ID].each { |k| ENV.delete(k) } }

  def hit(chat_id, text, secret: "s3cret")
    post "/telegram/webhook", params: { message: { chat: { id: chat_id }, from: { id: chat_id }, text: } }, as: :json,
         headers: { "X-Telegram-Bot-Api-Secret-Token" => secret }
  end

  test "비밀 토큰이 다르면 403" do
    assert_no_enqueued_jobs { hit(777, "상태", secret: "wrong") }
    assert_response :forbidden
  end

  test "허용된 채팅이면 잡을 넣고 200" do
    assert_enqueued_with(job: TelegramCommandJob, args: [ "777", "헬스체크" ]) { hit(777, "헬스체크") }
    assert_response :ok
  end

  test "알림 채널의 글(channel_post)도 받는다" do
    assert_enqueued_with(job: TelegramCommandJob, args: [ "-100555", "미수금" ]) do
      post "/telegram/webhook", params: { channel_post: { chat: { id: -100555 }, text: "미수금" } }, as: :json,
           headers: { "X-Telegram-Bot-Api-Secret-Token" => "s3cret" }
    end
    assert_response :ok
  end

  test "다른 채팅은 무시하고 200" do
    assert_no_enqueued_jobs { hit(999, "헬스체크") }
    assert_response :ok
  end
end
