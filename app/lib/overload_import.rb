require "json"

# 옛 Overload(Turso) 반출 JSON을 가져온다. 한 번 쓰고 버리는 코드.
#   bin/rails overload:import[/path/turso-export.json]
# 옛 id → 새 레코드 매핑으로 관계를 복원하고, 전부 한 트랜잭션에서 넣는다.
module OverloadImport
  def self.run(path)
    data = JSON.parse(File.read(path))

    Client.transaction do
      clients = data.fetch("projects").to_h do |p|
        [ p["id"], Client.create!(
          name: p["name"], kind: p["type"], status: p["status"],
          health_url: p["health_check_url"], vercel_project_id: p["vercel_project_id"],
          vercel_team_id: p["vercel_team_id"], supabase_ref: p["supabase_project_id"],
          notes: [ p["description"], p["notes"] ].compact_blank.join("\n").presence,
          created_at: p["created_at"]
        ) ]
      end

      contracts = data.fetch("contracts").to_h do |c|
        [ c["id"], clients.fetch(c["project_id"]).contracts.create!(
          name: c["client_name"], business_number: c["business_number"], amount: c["total_amount"],
          starts_on: c["start_date"], ends_on: c["end_date"], status: c["status"],
          notes: c["notes"], created_at: c["created_at"]
        ) ]
      end

      data.fetch("payments").each do |p|
        contracts.fetch(p["contract_id"]).payments.create!(
          kind: p["type"], amount: p["amount"], due_on: p["due_date"], paid_on: p["paid_at"],
          status: p["status"], created_at: p["created_at"]
        )
      end
    end

    { clients: Client.count, contracts: Contract.count, payments: Payment.count, paid: Payment.paid.sum(:amount) }
  end
end
