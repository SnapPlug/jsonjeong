# 텔레그램 명령 실행 + 그 대화창으로 답장. 헬스체크는 수십 초 걸릴 수 있어 웹훅 밖(잡)에서 돈다.
class TelegramCommandJob < ApplicationJob
  queue_as :default

  def perform(chat_id, text)
    reply = TelegramCommands.run(text)
    Telegram.post(chat_id: chat_id, text: reply, disable_web_page_preview: true)
  rescue => e
    Telegram.post(chat_id: chat_id, text: "⚠️ 실행 실패: #{e.class} #{e.message.first(200)}")
    raise
  end
end
