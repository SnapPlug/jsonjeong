require "test_helper"

class HealthLogTest < ActiveSupport::TestCase
  test "연속 2회째 실패에만 down, 3회째부터는 조용" do
    assert_nil HealthLog.transition([], false)
    assert_nil HealthLog.transition([ true ], false)
    assert_equal :down, HealthLog.transition([ true, false ], false)
    assert_equal :down, HealthLog.transition([ false ], false)
    assert_nil HealthLog.transition([ false, false ], false)
  end

  test "2회 이상 실패 뒤 첫 정상에만 up, 단발 실패 뒤 회복은 조용" do
    assert_equal :up, HealthLog.transition([ false, false ], true)
    assert_nil HealthLog.transition([ true, false ], true)
    assert_nil HealthLog.transition([ true, true ], true)
    assert_nil HealthLog.transition([], true)
  end

  test "latest는 체크마다 가장 최근 1건" do
    client = clients(:acme)
    client.health_logs.create!(check_type: "url", ok: true, checked_at: 2.hours.ago)
    newest_url = client.health_logs.create!(check_type: "url", ok: false, checked_at: 1.hour.ago)
    vercel = client.health_logs.create!(check_type: "vercel", ok: true, checked_at: 1.hour.ago)

    assert_equal [ newest_url.id, vercel.id ].sort, HealthLog.latest.pluck(:id).sort
  end

  test "purge!는 오래된 로그만 지운다" do
    client = clients(:acme)
    client.health_logs.create!(check_type: "url", ok: true, checked_at: 31.days.ago)
    kept = client.health_logs.create!(check_type: "url", ok: true, checked_at: 29.days.ago)

    HealthLog.purge!

    assert_equal [ kept.id ], HealthLog.pluck(:id)
  end

  test "고객사의 체크 종류는 입력된 서비스 정보로 정해진다" do
    assert_equal %w[url vercel], clients(:acme).checks
    assert_empty clients(:channel_only).checks
    assert_equal [ clients(:acme) ], Client.monitored.to_a
  end
end
