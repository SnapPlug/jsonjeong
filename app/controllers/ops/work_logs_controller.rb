module Ops
  class WorkLogsController < BaseController
    def create
      client = Client.find(params[:client_id])
      log = client.work_logs.new(params.expect(work_log: [ :worked_on, :minutes, :kind, :note ]))
      if log.save
        redirect_to ops_client_path(client, anchor: "work"), notice: "작업 시간을 기록했습니다"
      else
        redirect_to ops_client_path(client, anchor: "work"), alert: log.errors.full_messages.join(", ")
      end
    end
  end
end
