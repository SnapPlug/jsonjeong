require "test_helper"

class ContractTest < ActiveSupport::TestCase
  test "납부 합계가 계약 금액과 다르면 생성할 수 없다" do
    contract = clients(:acme).contracts.build(name: "2차", amount: 1_000_000, starts_on: Date.new(2026, 10, 1), ends_on: Date.new(2026, 10, 31))
    contract.payments.build(kind: "deposit", amount: 300_000, due_on: contract.starts_on)

    assert_not contract.valid?
    assert_match "합계", contract.errors[:payments].first
  end

  test "기본 납부 일정은 50/50이고 오차는 잔금이 흡수한다" do
    contract = clients(:acme).contracts.build(name: "2차", amount: 1_000_001, starts_on: Date.new(2026, 10, 1), ends_on: Date.new(2026, 10, 31))
    rows = contract.build_default_payments

    assert_equal %w[deposit balance], rows.map(&:kind)
    assert_equal [ 500_000, 500_001 ], rows.map(&:amount)
    assert_equal [ Date.new(2026, 10, 1), Date.new(2026, 10, 31) ], rows.map(&:due_on)
    assert contract.save
  end

  test "중도금 포함이면 30/40/30이고 중도금 날짜는 기간의 가운데" do
    contract = clients(:acme).contracts.build(name: "3차", amount: 1_000_000, starts_on: Date.new(2026, 10, 1), ends_on: Date.new(2026, 10, 31))
    rows = contract.build_default_payments(interim: true)

    assert_equal [ 300_000, 400_000, 300_000 ], rows.map(&:amount)
    assert_equal Date.new(2026, 10, 16), rows[1].due_on
  end

  test "종료일이 지난 진행 중 계약만 연체로 바뀐다" do
    old = clients(:acme).contracts.create!(name: "옛 계약", amount: 100, starts_on: 2.months.ago.to_date, ends_on: 1.month.ago.to_date)

    Contract.mark_overdue!

    assert old.reload.overdue?
    assert contracts(:acme_first).reload.in_progress?
  end

  test "이름의 앞뒤 공백은 지워진다" do
    contract = clients(:acme).contracts.create!(name: "  공백 계약 ", amount: 1, starts_on: Date.current, ends_on: Date.current)
    assert_equal "공백 계약", contract.name
  end
end
