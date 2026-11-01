module Ops
  # 텔레그램 → ops. 봇에게 보낸 메시지가 웹훅으로 들어온다. 로그인 대신 텔레그램 비밀 토큰 헤더로 확인하고,
  # 허용된 채팅(Jason 개인 대화, Overload 채널)만 받는다. 채널은 Jason만 글을 쓸 수 있다. 실제 일은 잡에서 하고 여기서는 바로 200을 돌려준다.
  class TelegramController < ActionController::API
    def create
      return head :forbidden unless valid_secret?
      message = params[:message] || params[:edited_message] || params[:channel_post]
      return head :ok unless message

      chat_id = message.dig(:chat, :id).to_s
      text = message[:text].to_s
      if TelegramCommands.allowed_chat_ids.include?(chat_id) && text.present?
        TelegramCommandJob.perform_later(chat_id, text)
      else
        Rails.logger.info("[telegram] 무시: chat=#{chat_id} from=#{message.dig(:from, :id)} text=#{text.first(40).inspect}")
      end
      head :ok
    end

    private
      def valid_secret?
        expected = ENV["TELEGRAM_WEBHOOK_SECRET"].to_s
        given = request.headers["X-Telegram-Bot-Api-Secret-Token"].to_s
        expected.present? && ActiveSupport::SecurityUtils.secure_compare(expected, given)
      end
  end
end
