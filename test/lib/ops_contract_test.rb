require "test_helper"

class OpsContractTest < ActiveSupport::TestCase
  test "새 고객사와 50/50 납부 일정을 만든다" do
    payload = Base64.strict_encode64({ client: "더온실", name: "검색 유입 기반 구축", amount: 1_000_000,
                                       starts_on: "2026-11-01", ends_on: "2026-11-30", kind: "rails" }.to_json)
    assert_difference [ "Client.count", "Contract.count" ], 1 do
      OpsContract.run(payload)
    end
    contract = Contract.last
    assert_equal "더온실", contract.client.name
    assert_equal [ 500_000, 500_000 ], contract.payments.map(&:amount)
  end

  test "기존 고객사면 재계약, 직접 입력 납부면 그대로" do
    payload = Base64.strict_encode64({ client: clients(:acme).name, name: "유지보수", amount: 300_000,
                                       starts_on: "2026-11-01", ends_on: "2027-01-31",
                                       payments: [ { kind: "balance", amount: 300_000, due_on: "2027-01-31" } ] }.to_json)
    assert_no_difference "Client.count" do
      OpsContract.run(payload)
    end
    assert_equal 1, Contract.last.payments.size
  end
end
