require "test_helper"
require "base64"
require "rake"

# 카나리 테스트 — 피클 credential-enclave의 canary.rs를 ops 크기로 줄인 것.
# 비밀값마다 고유 마커를 심고, ops의 모든 경로·잡·rake 작업을 돌린 뒤 두 가지를 본다.
#   C1: 응답·로그·DB·표준 출력 어디에도 마커가 없다 (그대로, 16진수, base64 세 가지 정렬)
#   C2: 바깥 요청에서 마커는 정해진 상대의 정해진 자리에만 있다 (텔레그램 본문에 비밀이 실리면 실패)
# 바깥 서비스는 가짜다. 정직(honest) · 받은 요청을 되돌려 보냄(echo) · 주소를 담은 네트워크 오류(raise) 세 가지로 돈다.
class CanaryTest < ActionDispatch::IntegrationTest
  # 바깥 연결 흉내. mode가 nil이면 진짜 Net::HTTP 그대로다(다른 테스트에 영향 없음).
  module FakeNet
    class << self
      attr_accessor :mode, :sent
    end

    def connect
      super unless FakeNet.mode
    end

    def request(req, body = nil, &block)
      return super unless FakeNet.mode
      FakeNet.sent << { host: address, path: req.path, headers: req.each_header.to_h, body: (body || req.body).to_s }
      raise SocketError, "Failed to open TCP connection to https://#{address}#{req.path}" if FakeNet.mode == :raise
      FakeNet.respond(address, req)
    end

    def self.respond(host, req)
      echo = "echo #{req['authorization']} #{req.path} #{req.body}"
      code, body = case host
      when "api.telegram.org" then [ 200, (mode == :echo ? { ok: false, description: echo } : { ok: true, result: [] }).to_json ]
      when "api.vercel.com" then mode == :echo ? [ 401, echo ] : [ 200, { deployments: [ { readyState: "ERROR" } ] }.to_json ]
      when "api.supabase.com" then mode == :echo ? [ 200, echo ] : [ 200, [ { table_name: "users", columns: "email" } ].to_json ]
      when "hc-ping.com" then [ 200, "OK" ]
      else [ 500, mode == :echo ? { failed: [ echo ] }.to_json : "down" ]
      end
      response = Net::HTTPResponse::CODE_TO_OBJ.fetch(code.to_s, Net::HTTPResponse).new("1.1", code.to_s, "fake")
      response["content-type"] = body.start_with?("{", "[") ? "application/json" : "text/html"
      response.instance_variable_set(:@body, body)
      response.instance_variable_set(:@read, true)
      response
    end
  end
  Net::HTTP.prepend(FakeNet)

  # ENV 이름 → 마커로 실제 값을 만드는 법
  SECRETS = {
    "TELEGRAM_BOT_TOKEN" => ->(m) { "7000000001:#{m}" },
    "TELEGRAM_WEBHOOK_SECRET" => ->(m) { m },
    "VERCEL_TOKEN" => ->(m) { m },
    "SUPABASE_ACCESS_TOKEN" => ->(m) { "sbp_#{m}" },
    "HEALTHCHECKS_URL" => ->(m) { "https://hc-ping.com/#{m}" },
    "OPS_AUDIT_SSH_KEY" => ->(m) { m.unpack1("H*") }, # 16진수로 들어와 ssh 키 파일로 풀린다
    "OPS_PASSWORD" => ->(m) { m }
  }.freeze

  # 마커가 나가도 되는 곳: [상대, 자리]. 웹훅 비밀은 setWebhook 등록 때 텔레그램에 넘기는 것이 원래 동작이다.
  ALLOWED = {
    "TELEGRAM_BOT_TOKEN" => [ "api.telegram.org", :path ],
    "TELEGRAM_WEBHOOK_SECRET" => [ "api.telegram.org", :"본문·기타 헤더" ],
    "VERCEL_TOKEN" => [ "api.vercel.com", :authorization ],
    "SUPABASE_ACCESS_TOKEN" => [ "api.supabase.com", :authorization ],
    "HEALTHCHECKS_URL" => [ "hc-ping.com", :path ],
    "OPS_AUDIT_SSH_KEY" => [ "ssh", :key ]
  }.freeze

  setup do
    @markers = (SECRETS.keys + [ "로그인 비밀번호" ]).to_h { |name| [ name, "CNRY#{SecureRandom.hex(12)}" ] }
    @saved_env = ENV.to_h
    SECRETS.each { |name, build| ENV[name] = build.call(@markers[name]) }
    ENV["TELEGRAM_CHAT_ID"] = "-100555"
    ENV["TELEGRAM_ADMIN_CHAT_ID"] = "777"
    ENV["OPS_EMAIL"] = "canary@example.com"

    @seen = []
    @log = StringIO.new
    @log_target = ActiveSupport::Logger.new(@log)
    Rails.logger.broadcast_to(@log_target)
    @actions = Set.new
    @subscription = ActiveSupport::Notifications.subscribe("process_action.action_controller") do |*, payload|
      @actions << "#{payload[:controller].delete_suffix('Controller').underscore}##{payload[:action]}"
    end
    FakeNet.sent = []
    host! "ops.example.com"
  end

  teardown do
    FakeNet.mode = nil
    Rails.logger.stop_broadcasting_to(@log_target)
    ActiveSupport::Notifications.unsubscribe(@subscription)
    ENV.replace(@saved_env)
  end

  %i[honest echo raise].each do |mode|
    test "비밀값이 정해진 곳 밖으로 새지 않는다 (바깥 서비스: #{mode})" do
      FakeNet.mode = mode
      stubbing(HealthCheck, :sleep, nil) { walk } # 재시도 대기 2초는 건너뛴다
      assert_empty leaks, "새는 곳:\n#{leaks.join("\n")}"
      assert_empty ops_routes - @actions, "카나리가 안 지나간 경로"
    end
  end

  private
    def walk
      client = Client.create!(name: "카나리", kind: "rails", status: "active", stack_version: "8.1.0",
                              health_url: "https://canary.example.com/health", vercel_project_id: "prj_c", supabase_ref: "canaryref")
      User.create!(email_address: "canary@example.com", password: @markers["로그인 비밀번호"])

      # 로그인 전
      %w[/ /contracts /contracts/new].each { |path| hit(:get, path) }
      hit(:get, "/clients/#{client.id}")
      hit(:get, "/session/new")
      hit(:post, "/session", params: { email_address: "canary@example.com", password: "x#{@markers['로그인 비밀번호']}" })
      hit(:post, "/session", params: { email_address: "canary@example.com", password: @markers["로그인 비밀번호"] })

      # 로그인 뒤 — 성공과 실패를 하나씩
      %w[/ /contracts /contracts/new].each { |path| hit(:get, path) }
      hit(:get, "/clients/#{client.id}")
      hit(:post, "/contracts", params: { client_name: "카나리2", schedule: "half", contract: { name: "새 계약", amount: 1000, starts_on: "2026-11-01", ends_on: "2026-12-01" } })
      hit(:post, "/contracts", params: { client_name: "카나리3", contract: { name: "", amount: 0 } })
      hit(:patch, "/clients/#{client.id}", params: { client: { notes: "메모" } })
      hit(:patch, "/clients/#{client.id}", params: { client: { name: "" } })
      hit(:patch, "/payments/#{payments(:acme_balance).id}", params: { payment: { status: "paid" } })
      hit(:patch, "/contracts/#{contracts(:acme_first).id}", params: { contract: { status: "in_progress" } })
      hit(:post, "/health_check")

      # 텔레그램 웹훅 — 비밀 틀림, 허용 채팅, 모르는 채팅, 빈 몸통
      webhook(@markers["TELEGRAM_WEBHOOK_SECRET"].reverse, 777)
      webhook(@markers["TELEGRAM_WEBHOOK_SECRET"], 777)
      webhook(@markers["TELEGRAM_WEBHOOK_SECRET"], 123)
      hit(:post, "/telegram/webhook", headers: { "X-Telegram-Bot-Api-Secret-Token" => @markers["TELEGRAM_WEBHOOK_SECRET"] }, as: :json, params: {})

      # 잡 — 헬스체크 3번(연속 실패 알림까지), 텔레그램 명령 전부, 플랫폼 소식, 주간 보안 점검
      3.times { HealthCheckJob.perform_now }
      %w[상태 헬스체크 미수금 도움말 아무말].each { |text| run_job { TelegramCommandJob.perform_now("777", text) } }
      run_job { PlatformWatchJob.perform_now }
      stubbing(Open3, :capture2e, method(:fake_ssh)) { run_job { SecurityAuditJob.perform_now } }
      run_job { Telegram.recent_chat_ids }

      # rake — 표준 출력까지 본다
      Rails.application.load_tasks unless Rake::Task.task_defined?("ops:password")
      %w[ops:password ops:telegram_webhook].each do |task|
        out, err = capture_io { run_job { Rake::Task[task].execute } }
        @seen << [ "rake #{task} 출력", out + err ]
      end
    end

    def hit(verb, path, **options)
      send(verb, path, **options)
      @seen << [ "응답 #{verb.upcase} #{path}", [ response.status, response.headers.to_h, response.body ].inspect ]
    end

    def webhook(secret, chat_id)
      hit(:post, "/telegram/webhook", as: :json, headers: { "X-Telegram-Bot-Api-Secret-Token" => secret },
          params: { message: { chat: { id: chat_id }, from: { id: chat_id }, text: "상태" } })
    end

    # 실패해도 다음 단계는 돈다. 예외 글도 새는 곳이 될 수 있으니 본다.
    def run_job
      yield
    rescue => e
      @seen << [ "예외", "#{e.class} #{e.message}" ]
    end

    def fake_ssh(*args)
      key = File.binread(args[args.index("-i") + 1])
      FakeNet.sent << { host: "ssh", path: "", headers: {}, body: "", key: }
      [ "#{args.last}: Permission denied (publickey).\n", Struct.new(:success?).new(false) ]
    end

    def ops_routes
      Rails.application.routes.routes.filter_map do |route|
        controller, action = route.defaults.values_at(:controller, :action)
        "#{controller}##{action}" if controller&.start_with?("ops/")
      end.to_set + %w[sessions#new sessions#create]
    end

    def db_dump
      connection = ActiveRecord::Base.connection
      connection.tables.map { |table| connection.select_all("SELECT * FROM #{connection.quote_table_name(table)}").rows.inspect }.join("\n")
    end

    # 그대로, 16진수, base64(앞에 붙은 글자 수 0·1·2 → 세 가지 정렬). 가장자리 글자는 앞뒤 문맥에 따라 바뀌니 뺀다.
    def forms(marker)
      base64 = (0..2).map { |pad| Base64.strict_encode64(("a" * pad) + marker)[4..-5] }
      [ marker, marker.unpack1("H*"), *base64, *base64.map { |b| b.tr("+/", "-_") } ]
    end

    def leaks
      @leaks ||= begin
        places = @seen + [ [ "로그", @log.string ], [ "DB", db_dump ] ]
        @markers.flat_map do |name, marker|
          patterns = forms(marker)
          found = places.filter_map { |where, text| "#{name} → #{where}" if patterns.any? { |p| text.include?(p) } }
          found + FakeNet.sent.flat_map do |request|
            {
              path: request[:path],
              authorization: request[:headers]["authorization"].to_s,
              key: request[:key].to_s,
              "본문·기타 헤더": request[:headers].except("authorization").to_a.join(" ") + request[:body]
            }.filter_map do |place, text|
              next unless patterns.any? { |p| text.include?(p) }
              "#{name} → #{request[:host]} #{place}" unless ALLOWED[name] == [ request[:host], place ]
            end
          end
        end.uniq
      end
    end
end
