require "test_helper"

class PaymentTest < ActiveSupport::TestCase
  test "마감일이 지난 미수금은 연체로 바뀌고 수금 완료로 바꾸면 수금일이 채워진다" do
    late = contracts(:acme_first).payments.create!(kind: "interim", amount: 1, due_on: Date.yesterday)

    Payment.mark_overdue!
    assert late.reload.overdue?
    assert payments(:acme_balance).reload.pending?

    late.update!(status: "paid")
    assert_equal Date.current, late.paid_on
  end

  test "월별 수금 합계는 마감일 기준으로 수금 완료분만 센다" do
    month = payments(:acme_deposit).due_on.strftime("%Y-%m")
    totals = Payment.monthly_paid(months: 120)

    assert_equal 1_000_000, totals[month]
    assert_equal 1_000_000, totals.values.sum
  end

  test "미수금은 마감일 순으로 미납·연체만" do
    assert_equal [ payments(:acme_balance) ], Payment.unpaid.to_a
  end
end
