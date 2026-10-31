require "base64"
require "json"

# 계약서에서 뽑은 JSON 하나로 고객사+계약+납부 일정을 등록한다. /ops-contract 스킬이 부른다.
# 입력(JSON): client(필수) name amount starts_on ends_on [business_number notes schedule=half|thirds|none payments=[{kind,amount,due_on}] kind health_url]
# 고객사 이름이 기존과 같으면 재계약, 아니면 생성 — 새 계약 폼(Ops::ContractsController#create)과 같은 규칙.
module OpsContract
  def self.run(base64_json)
    data = JSON.parse(Base64.decode64(base64_json))
    client = Client.find_or_initialize_by(name: data.fetch("client"))
    client.kind = data["kind"] if data["kind"]
    client.health_url = data["health_url"] if data["health_url"]

    contract = Contract.new(data.slice("name", "amount", "starts_on", "ends_on", "business_number", "notes"))
    contract.client = client
    if data["payments"].present?
      data["payments"].each { |p| contract.payments.build(p.slice("kind", "amount", "due_on")) }
    elsif data.fetch("schedule", "half") != "none"
      contract.build_default_payments(interim: data["schedule"] == "thirds")
    end

    Contract.transaction { client.save!; contract.save! }
    "[ops] #{client.name} · #{contract.name} · #{contract.amount}원 · 납부 #{contract.payments.size}건 등록"
  end
end
