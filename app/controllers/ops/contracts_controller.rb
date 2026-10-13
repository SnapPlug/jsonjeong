module Ops
  class ContractsController < BaseController
    SCHEDULES = %w[half thirds none manual].freeze

    def new
      @contract = Contract.new(starts_on: Date.current, ends_on: Date.current + 1.month)
      @client_name = params[:client_name]
      @schedule = "half"
      @client_names = Client.order(:name).pluck(:name)
    end

    # 폼 하나로 고객사까지 처리한다: 이름이 기존 고객사와 같으면 재계약, 아니면 그 자리에서 생성.
    def create
      @client_name = params[:client_name].to_s
      @schedule = SCHEDULES.include?(params[:schedule]) ? params[:schedule] : "half"
      client = Client.find_or_initialize_by(name: @client_name)
      # client.contracts.build 대신 따로 만든다 — 그래야 고객사 저장이 계약을 같이 저장하려 들지 않고,
      # 검증 오류가 고객사 것인지 계약 것인지 그대로 드러난다.
      @contract = Contract.new(contract_params)
      @contract.client = client
      build_schedule

      Contract.transaction do
        client.save!
        @contract.save!
      end
      redirect_to ops_client_path(client), notice: "계약을 등록했습니다"
    rescue ActiveRecord::RecordInvalid => e
      @errors = e.record.errors.full_messages
      @client_names = Client.order(:name).pluck(:name)
      render :new, status: :unprocessable_entity
    end

    def update
      contract = Contract.find(params[:id])
      contract.update!(params.expect(contract: [ :status ]))
      redirect_back_or_to ops_client_path(contract.client)
    end

    private
      def contract_params
        permitted = params.require(:contract).permit(:name, :amount, :starts_on, :ends_on, :business_number, :notes,
                                                     payments_attributes: [ :kind, :amount, :due_on ])
        @schedule == "manual" ? permitted : permitted.except(:payments_attributes)
      end

      def build_schedule
        return unless %w[half thirds].include?(@schedule)
        return unless @contract.amount.to_i > 0 && @contract.starts_on && @contract.ends_on
        @contract.build_default_payments(interim: @schedule == "thirds")
      end
  end
end
