module Ops
  class ClientsController < BaseController
    before_action :set_client

    def show
      @contracts = @client.contracts.order(starts_on: :desc)
      @payments = @client.payments.includes(:contract).order(:due_on)
      @logs = @client.health_logs.order(checked_at: :desc).limit(40)
    end

    def update
      if @client.update(client_params)
        redirect_to ops_client_path(@client), notice: "저장했습니다"
      else
        redirect_to ops_client_path(@client), alert: @client.errors.full_messages.join(", ")
      end
    end

    private
      def set_client
        @client = Client.find(params[:id])
      end

      def client_params
        params.expect(client: [ :name, :kind, :status, :health_url, :vercel_project_id, :vercel_team_id, :supabase_ref, :notes ])
      end
  end
end
