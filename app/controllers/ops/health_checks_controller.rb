module Ops
  # "지금 체크" 버튼. 체크는 최대 수십 초가 걸릴 수 있어 큐에 넣고 바로 돌아온다.
  class HealthChecksController < BaseController
    def create
      HealthCheckJob.perform_later
      redirect_to ops_root_path, notice: "체크를 시작했습니다. 잠시 뒤 새로고침하세요."
    end
  end
end
