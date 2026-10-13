module Ops
  # ops.jsonjeong.com — 계약현황·헬스체크 관제. ApplicationController의 인증 필수가 그대로 적용된다.
  class BaseController < ApplicationController
    layout "ops"
    helper_method :sidebar_clients, :sidebar_health

    private
      def sidebar_clients
        # 진행중 먼저, 완료·일시중지는 뒤에. 완료된 고객사도 계약 기록을 봐야 하니 숨기지 않는다.
        @sidebar_clients ||= Client.order(Arel.sql("CASE status WHEN 'active' THEN 0 ELSE 1 END"), :name)
      end

      def sidebar_health
        @sidebar_health ||= HealthLog.latest.group_by(&:client_id)
      end
  end
end
