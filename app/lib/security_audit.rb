require "open3"
require "net/http"
require "base64"

# 주간 보안 점검 (매주 월 09:00 KST, config/recurring.yml). 2026-11-08 손 점검에서 찾은 종류만 기계가 다시 본다.
# 결과는 문제 한 줄씩의 목록이다. 빈 목록이면 이상 없음. 코드 논리 결함(쿠키 값 검증 등)은 못 잡는다 — 분기 손 점검 몫.
module SecurityAudit
  # ponytail: 서버가 셋뿐이라 박아 둠. 늘면 여기에 더한다. 각 서버의 authorized_keys에 점검 키가 강제 명령으로 걸려 있다.
  SERVERS = { "69.55.54.59" => "ops", "158.247.200.165" => "snaptalk·로컬바이브랩", "172.237.119.122" => "GrabReceipts" }.freeze
  PROBE_PATHS = %w[/.env /.git/config].freeze
  SENSITIVE = /email|phone|mobile|business_number|commission|password|token|secret|account_number|birth/i

  def self.run
    clients = Client.where.not(status: "paused")
    origins = clients.where.not(health_url: nil).to_h { |c| [ origin(c.health_url), c.name ] }
    origins.flat_map { |url, name| web(name, url) } +
      clients.where.not(supabase_ref: nil).flat_map { |c| database(c.name, c.supabase_ref) } +
      SERVERS.flat_map { |host, label| server(host, label) }
  end

  def self.origin(url)
    uri = URI(url)
    "#{uri.scheme}://#{uri.host}"
  end

  # 첫 화면의 헤더·쿠키, 그리고 열리면 안 되는 파일. 헤더는 HTML일 때만 본다(헬스 JSON에 프레임 차단은 뜻이 없다).
  def self.web(name, origin)
    page = HealthCheck.get("#{origin}/")
    return [ "#{name}: #{origin} 접속 실패 (#{page.error})" ] if page.error

    issues = []
    headers = page.headers
    if html?(page)
      framing = headers["x-frame-options"] || headers["content-security-policy"].to_a.join.include?("frame-ancestors")
      issues << "프레임 차단 헤더 없음" unless framing
      issues << "HSTS 없음" unless headers["strict-transport-security"]
    end
    insecure = headers["set-cookie"].to_a.grep_v(/;\s*secure/i).map { |cookie| cookie[/\A[^=]+/] }
    issues << "secure 없는 쿠키 #{insecure.join(', ')}" if insecure.any?
    PROBE_PATHS.each do |path|
      response = HealthCheck.get("#{origin}#{path}")
      issues << "#{path} 열림" if response.code == 200 && !html?(response) # 첫 화면(HTML)으로 풀리는 건 비밀이 아니다
    end
    issues.map { |issue| "#{name}: #{issue}" }
  end

  # 공개 키(anon)로 읽히는 민감한 칸. 2026-11-06 더온실 partners(anon SELECT 정책 + email·사업자번호) 같은 건.
  # anon에 SELECT 권한이 있고, RLS가 꺼졌거나 anon용 SELECT 정책이 있거나, 소유자 권한으로 도는 뷰면 잡는다.
  # Supabase는 공개 키로 테이블 목록을 주지 않아(401) 관리 API로 카탈로그를 읽는다. 토큰이 보는 계정의 프로젝트만 된다.
  EXPOSED_SQL = <<~SQL.freeze
    select t.relname as table_name, string_agg(a.attname, ', ' order by a.attnum) as columns
    from pg_class t
    join pg_namespace n on n.oid = t.relnamespace and n.nspname = 'public'
    join pg_attribute a on a.attrelid = t.oid and a.attnum > 0 and not a.attisdropped
    where t.relkind in ('r', 'v', 'm')
      and a.attname ~* '#{SENSITIVE.source}'
      and has_column_privilege('anon', t.oid, a.attnum, 'SELECT')
      and (
        (t.relkind = 'r' and (not t.relrowsecurity or exists (
          select 1 from pg_policies p where p.schemaname = 'public' and p.tablename = t.relname
            and p.cmd in ('SELECT', 'ALL') and 'anon' = any(p.roles))))
        or (t.relkind <> 'r' and coalesce(array_to_string(t.reloptions, ','), '') not ilike '%security_invoker=true%')
      )
    group by t.relname order by t.relname
  SQL

  def self.database(name, ref)
    token = ENV["SUPABASE_ACCESS_TOKEN"].to_s.strip
    return [ "#{name}: Supabase 점검 건너뜀 (SUPABASE_ACCESS_TOKEN 미설정)" ] if token.empty?

    response = supabase_query(ref, token)
    return [ "#{name}: Supabase 점검 실패 (#{response.error || "HTTP #{response.code}"})" ] unless response.code.to_i.between?(200, 299)
    JSON.parse(response.body).map { |row| "#{name}: 공개 키로 #{row['table_name']}의 #{row['columns']} 읽힘" }
  rescue JSON::ParserError => e
    [ "#{name}: Supabase 응답 해석 실패 (#{e.message[0, 60]})" ]
  end

  def self.supabase_query(ref, token)
    uri = URI("https://api.supabase.com/v1/projects/#{ref}/database/query")
    response = Net::HTTP.post(uri, { query: EXPOSED_SQL, read_only: true }.to_json,
                              "Authorization" => "Bearer #{token}", "Content-Type" => "application/json")
    HealthCheck::Response.new(code: response.code.to_i, body: response.body, ms: 0, error: nil)
  rescue => e
    HealthCheck::Response.new(code: nil, body: nil, ms: 0, error: "#{e.class}: #{e.message}")
  end

  # 점검 키로 접속하면 서버가 강제 명령(/usr/local/sbin/ops-audit-status)만 돌려 "reboot=… password=…"을 준다.
  def self.server(host, label)
    key = Base64.decode64(ENV["OPS_AUDIT_SSH_KEY"].to_s)
    return [ "서버 #{label}: 점검 키 미설정" ] if key.strip.empty?

    out, status = Tempfile.create("ops_audit_key") do |file|
      file.write(key)
      file.flush
      File.chmod(0o600, file.path)
      Open3.capture2e("ssh", "-i", file.path, "-o", "BatchMode=yes", "-o", "ConnectTimeout=10",
                      "-o", "StrictHostKeyChecking=accept-new", "-o", "UserKnownHostsFile=#{Rails.root.join('storage', 'known_hosts')}",
                      "root@#{host}")
    end
    return [ "서버 #{label}: 접속 실패 (#{out.lines.last.to_s.strip})" ] unless status.success?
    server_issues(label, out)
  end

  def self.server_issues(label, out)
    issues = []
    issues << "재부팅 대기 (보안 업데이트 미적용)" if out.include?("reboot=yes")
    issues << "SSH 비밀번호 로그인 켜짐" if out.include?("password=yes")
    issues.map { |issue| "서버 #{label}: #{issue}" }
  end

  def self.html?(response) = response.headers["content-type"].to_a.join.include?("text/html")
end
