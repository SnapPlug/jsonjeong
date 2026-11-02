require "test_helper"

class PlatformEventTest < ActiveSupport::TestCase
  test "장애 제목에서 리전을 읽는다" do
    {
      "Storage uploads failing in us-east-1" => [ "us-east-1" ],
      "Project creation errors ap-ne1" => [ "ap-northeast-1" ],
      "Supavisor connection disruptions in EU West 1 (Ireland)" => [ "eu-west-1" ],
      "Errors in us-east-1 and eu-central-1" => [ "us-east-1", "eu-central-1" ],
      "Logs degraded in multiple regions" => [],
      "Intermittent latency in Eastern US" => [],
      "Project lifecycle operation errors in the EU region" => []
    }.each { |title, regions| assert_equal regions, PlatformEvent.new(title:).regions, title }
  end

  test "실제 장애 제목으로 본 우리 영향 판정" do
    touches = ->(source, title) { PlatformEvent.new(source:, title:).touches_us? }
    {
      "supabase" => [ "Storage uploads failing in us-east-1", "Intermittent connection errors via the connection pooler in us-east-1" ],
      "vercel" => [ "Build failures and 500 errors for functions using Edge runtime", "Degraded performance on CDN, Dashboard, Functions in Washington, Cleveland (iad1, cle1)", "Dynamic API routes returned 404 errors for some deployments" ],
      "cloudflare" => [ "Increased Worker services errors", "Increased Durable Objects, D1 and Workflows Error Rates" ]
    }.each { |source, titles| titles.each { |title| assert touches.call(source, title), title } }
    {
      "supabase" => [ "Logs degraded in multiple regions", "PG15 -> PG17 Upgrade Failures", "Elevated Mgmt API Error Rates in Multiple Regions", "Storage search failing for restored projects", "Project creation errors ap-ne1" ],
      "vercel" => [ "Increased build and deployment failures", "Delays in Drains, Observability, and Workflow in Washington (iad1)", "Elevated Function Invocation Errors in Stockholm region (ARN1)", "Vercel Auth login failures for pages with Deployment Protection enabled" ],
      "cloudflare" => [ "Worker Deployments Delayed", "Cache purge delays in Qingdao Shandong, China", "Increased Errors for Browser Run", "Elevated Errors for R2 and Durable Objects in ENAM", "Delayed, missed, and duplicated Workers Cron Triggers" ]
    }.each { |source, titles| titles.each { |title| assert_not touches.call(source, title), title } }
  end
end
