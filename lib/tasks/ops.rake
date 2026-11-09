namespace :ops do
  desc "OPS_EMAIL·OPS_PASSWORD로 관제 로그인 계정을 맞춘다. 컨테이너 시작 때 자동 실행되고, OPS_PASSWORD가 없으면 아무것도 안 한다"
  task password: :environment do
    password = ENV["OPS_PASSWORD"].to_s
    next if password.empty?

    email = ENV.fetch("OPS_EMAIL", "json.jeong@snapplug.app")
    user = User.find_or_initialize_by(email_address: email)
    next if user.persisted? && user.authenticate(password)

    user.update!(password:)
    puts "[ops] #{email} 비밀번호 적용"
  end
end

namespace :ops do
  desc "계약 등록: bin/rails ops:contract[<base64 JSON>] — 형식은 app/lib/ops_contract.rb 주석"
  task :contract, [ :payload ] => :environment do |_task, args|
    puts OpsContract.run(args.fetch(:payload))
  end
end

namespace :ops do
  desc "텔레그램 봇 웹훅을 ops.jsonjeong.com/telegram/webhook 으로 등록한다 (TELEGRAM_WEBHOOK_SECRET 필요)"
  task telegram_webhook: :environment do
    secret = ENV.fetch("TELEGRAM_WEBHOOK_SECRET")
    url = "https://ops.jsonjeong.com/telegram/webhook"
    r = Telegram.call("setWebhook", url:, secret_token: secret, allowed_updates: [ "message", "channel_post" ])
    puts "[ops] setWebhook #{r.is_a?(Hash) && r['ok'] ? '성공' : '실패'}" # 응답 전체를 찍지 않는다 — 비밀이 되돌아올 수 있다
  end
end
