module Ops
  # ops.jsonjeong.com — 계약현황·헬스체크 관제. ApplicationController의 인증 필수가 그대로 적용된다.
  class BaseController < ApplicationController
    layout "ops"
    helper_method :sidebar_clients, :sidebar_health

    private
      def sidebar_clients
        @sidebar_clients ||= Client.active.order(:name)
      end

      def sidebar_health
        @sidebar_health ||= HealthLog.latest.group_by(&:client_id)
      end
  end
end
