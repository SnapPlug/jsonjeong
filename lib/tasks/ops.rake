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
