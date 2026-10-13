module Ops
  class DashboardController < BaseController
    def index
      @open_contracts = Contract.in_progress.count
      @unpaid = Payment.unpaid.includes(contract: :client)
      @unpaid_total = @unpaid.sum(:amount)
      @paid_this_month = Payment.paid.where(due_on: Date.current.all_month).sum(:amount)

      @services = Client.monitored.order(:name)
      @latest = HealthLog.latest.group_by(&:client_id).transform_values { |logs| logs.index_by(&:check_type) }
      @unhealthy = @services.count { |client| @latest[client.id]&.values&.any? { |log| !log.ok } }

      @monthly = Payment.monthly_paid
      @months = (0..11).map { |i| (Date.current << i).strftime("%Y-%m") }.reverse
    end
  end
end
