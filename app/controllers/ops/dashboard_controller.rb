module Ops
  class DashboardController < BaseController
    def index
      @open_contracts = Contract.in_progress.count
      @unpaid = Payment.unpaid.includes(contract: :client)
      @unpaid_total = @unpaid.sum(:amount)
      @paid_this_month = Payment.paid.where(paid_on: Date.current.all_month).sum(:amount)
      @paid_this_year = Payment.paid.where(paid_on: Date.current.all_year).sum(:amount)

      @services = Client.monitored.order(:name)
      # 지금 켜진 체크만 본다. 감시를 끈 체크(예: Vercel 칸을 비움)의 마지막 실패가 남아 비정상으로 보이지 않게.
      latest = HealthLog.latest.group_by(&:client_id)
      @latest = @services.to_h { |client| [ client.id, (latest[client.id] || []).index_by(&:check_type).slice(*client.checks) ] }
      @unhealthy = @services.count { |client| @latest[client.id].values.any? { |log| !log.ok } }

      @platform_events = PlatformEvent.recent.limit(10)

      @monthly = Payment.monthly_paid
      @months = (0..11).map { |i| (Date.current << i).strftime("%Y-%m") }.reverse
      @last12_total = @monthly.values.sum
    end
  end
end
