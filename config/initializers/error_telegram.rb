# 처리되지 않은 예외(요청 500, 잡 실패)를 Overload 텔레그램 방으로 보낸다.
# 같은 예외는 10분에 한 통만 — 재시도하는 잡이 같은 예외를 반복하면 시간당 수천 통이 될 수 있다.
# Telegram 미설정(개발·테스트)이면 아무 일도 없다. snaptalk과 같은 파일.
class TelegramErrorReporter
  def report(error, handled:, severity:, context:, source: nil)
    return if handled || !Telegram.configured?

    key = "error_telegram:#{error.class}:#{error.message.to_s[0, 80]}"
    return unless Rails.cache.write(key, 1, expires_in: 10.minutes, unless_exist: true)

    Telegram.send_message([
      "🔴 #{Rails.application.class.module_parent_name} #{error.class}",
      error.message.to_s[0, 300],
      *Array(error.backtrace).first(3)
    ].join("\n"))
  rescue => e
    Rails.logger.error("[error_telegram] #{e.class} #{e.message}")
  end
end

Rails.application.config.after_initialize do
  Rails.error.subscribe(TelegramErrorReporter.new) if Rails.env.production?
end
