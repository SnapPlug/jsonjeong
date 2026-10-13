require "net/http"
require "json"

# 우리에게 알리는 길. snaptalk의 app/lib/telegram.rb를 그대로 가져왔다.
#
# 텔레그램을 고른 이유: 공짜고, 발신번호 등록도 SMTP 계정도 필요 없고, HTTP 한 번이다.
# 설정이 없으면 조용히 아무것도 안 한다 — 개발·테스트에서 알림이 울릴 이유가 없다.
module Telegram
  Result = Data.define(:ok, :error)

  def self.configured? = token.present? && chat_id.present?
  def self.token   = ENV["TELEGRAM_BOT_TOKEN"].to_s.strip.presence
  def self.chat_id = ENV["TELEGRAM_CHAT_ID"].to_s.strip.presence

  # 4096자가 텔레그램 한 통의 상한이다. 넘치면 뒤를 자르고 잘렸다고 밝힌다.
  LIMIT = 3_900

  def self.send_message(text)
    return Result.new(false, "미설정") unless configured?

    body = text.to_s
    body = "#{body[0, LIMIT]}\n…(줄여서 보냈습니다)" if body.length > LIMIT
    post(chat_id: chat_id, text: body, disable_web_page_preview: true)
  end

  # 봇에게 말을 건 사람의 chat_id를 찾아 준다. 설정할 때 한 번 쓴다.
  def self.recent_chat_ids
    r = call("getUpdates", nil)
    return [] unless r.is_a?(Hash) && r["ok"]
    Array(r["result"]).filter_map { |u|
      m = u["message"] || u["channel_post"] || {}
      c = m["chat"] || {}
      [ c["id"], c["title"] || [ c["first_name"], c["last_name"] ].compact.join(" ") ] if c["id"]
    }.uniq
  end

  def self.post(**body)
    r = call("sendMessage", body)
    return Result.new(false, "응답 없음") unless r.is_a?(Hash)
    r["ok"] ? Result.new(true, nil) : Result.new(false, r["description"].to_s)
  rescue => e
    Result.new(false, "#{e.class} #{e.message}")
  end

  def self.call(method, body)
    uri = URI("https://api.telegram.org/bot#{token}/#{method}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 10
    req = body ? Net::HTTP::Post.new(uri) : Net::HTTP::Get.new(uri)
    if body
      req["Content-Type"] = "application/json"
      req.body = body.to_json
    end
    JSON.parse(http.request(req).body)
  rescue => e
    Rails.logger.error("[telegram] #{e.class} #{e.message}")
    nil
  end
end
