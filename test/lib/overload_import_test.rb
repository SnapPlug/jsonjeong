require "test_helper"

class OverloadImportTest < ActiveSupport::TestCase
  test "Turso 반출 JSON을 관계까지 복원해 가져온다" do
    assert_difference [ "Client.count", "Contract.count" ], 2 do
      assert_difference "Payment.count", 3 do
        OverloadImport.run(file_fixture("turso-export.json"))
      end
    end

    theonsil = Client.find_by!(name: "더온실")
    assert_equal %w[url vercel supabase], theonsil.checks
    assert_equal "team_x", theonsil.vercel_team_id
    assert_equal "더온실 반려동물 장례 플랫폼 구축 계약", theonsil.contracts.sole.name
    assert_equal 2_000_000, theonsil.payments.paid.sum(:amount)
    assert_equal Date.new(2026, 6, 22), theonsil.payments.find_by(kind: "balance").paid_on

    wanjeon = Client.find_by!(name: "완전체")
    assert_equal "채널톡 CS\n메모", wanjeon.notes
    assert wanjeon.payments.sole.pending?
  end
end
