require "test_helper"

class Ops::ContractsControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "ops.example.com"
    sign_in_as users(:one)
  end

  test "새 이름으로 계약을 만들면 고객사가 같이 생기고 납부 일정은 50/50" do
    assert_difference [ "Client.count", "Contract.count" ], 1 do
      assert_difference "Payment.count", 2 do
        post "/contracts", params: { client_name: " 새고객 ", schedule: "half",
                                     contract: { name: "구축", amount: 3_000_001, starts_on: "2026-11-01", ends_on: "2026-11-30" } }
      end
    end

    client = Client.find_by!(name: "새고객")
    assert_redirected_to "/clients/#{client.id}"
    assert_equal [ 1_500_000, 1_500_001 ], client.payments.order(:due_on).pluck(:amount)
    assert_equal [ Date.new(2026, 11, 1), Date.new(2026, 11, 30) ], client.payments.order(:due_on).pluck(:due_on)
  end

  test "있는 고객사 이름이면 재계약으로 붙는다" do
    assert_no_difference "Client.count" do
      assert_difference "clients(:acme).contracts.count", 1 do
        post "/contracts", params: { client_name: "에이스상사", schedule: "none",
                                     contract: { name: "2차", amount: 500_000, starts_on: "2026-11-01", ends_on: "2026-11-30" } }
      end
    end
    assert_equal 0, clients(:acme).contracts.find_by!(name: "2차").payments.count
  end

  test "직접 입력한 납부 합계가 금액과 다르면 저장하지 않는다" do
    assert_no_difference [ "Client.count", "Contract.count", "Payment.count" ] do
      post "/contracts", params: { client_name: "새고객", schedule: "manual",
                                   contract: { name: "구축", amount: 1_000_000, starts_on: "2026-11-01", ends_on: "2026-11-30",
                                               payments_attributes: { "0" => { kind: "deposit", amount: 100, due_on: "2026-11-01" },
                                                                      "1" => { kind: "interim", amount: "", due_on: "" } } } }
    end
    assert_response :unprocessable_entity
    assert_match "합계", response.body
  end

  test "직접 입력은 빈 줄을 건너뛴다" do
    assert_difference "Payment.count", 2 do
      post "/contracts", params: { client_name: "에이스상사", schedule: "manual",
                                   contract: { name: "3차", amount: 1_000, starts_on: "2026-11-01", ends_on: "2026-11-30",
                                               payments_attributes: { "0" => { kind: "deposit", amount: 400, due_on: "2026-11-01" },
                                                                      "1" => { kind: "interim", amount: "", due_on: "" },
                                                                      "2" => { kind: "balance", amount: 600, due_on: "2026-11-30" } } } }
    end
  end

  test "고객사 이름이 비면 저장하지 않는다" do
    assert_no_difference "Contract.count" do
      post "/contracts", params: { client_name: " ", schedule: "half",
                                   contract: { name: "구축", amount: 1, starts_on: "2026-11-01", ends_on: "2026-11-30" } }
    end
    assert_response :unprocessable_entity
  end

  test "계약 상태를 바꾼다" do
    patch "/contracts/#{contracts(:acme_first).id}", params: { contract: { status: "completed" } }
    assert_redirected_to "/clients/#{clients(:acme).id}"
    assert contracts(:acme_first).reload.completed?
  end
end
