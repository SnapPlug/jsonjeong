require "test_helper"

class WorkLogTest < ActiveSupport::TestCase
  test "달별 합계는 최근 n달을 0까지 채워 오래된 순으로 준다" do
    acme = clients(:acme)
    acme.work_logs.create!(worked_on: Date.new(2026, 11, 2), minutes: 30, kind: "security")
    acme.work_logs.create!(worked_on: Date.new(2026, 11, 13), minutes: 15, kind: "server")
    acme.work_logs.create!(worked_on: Date.new(2026, 9, 1), minutes: 20, kind: "triage")
    acme.work_logs.create!(worked_on: Date.new(2026, 5, 31), minutes: 99, kind: "other") # 범위 밖

    assert_equal({ "2026-09" => 20, "2026-10" => 0, "2026-11" => 45 },
                 acme.work_logs.monthly_minutes(months: 3, today: Date.new(2026, 11, 13)))
  end

  test "분은 양의 정수, 종류는 정해진 것만" do
    log = clients(:acme).work_logs.new(worked_on: Date.current, minutes: 0, kind: "nope")
    assert_not log.valid?
    assert log.errors.key?(:minutes)
    assert log.errors.key?(:kind)
  end
end
