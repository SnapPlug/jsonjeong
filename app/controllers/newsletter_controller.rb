class NewsletterController < ApplicationController
  allow_unauthenticated_access only: [:show, :subscribe]

  NAME = "Vibe Coding Notes"
  PROMISE = "Weekly notes from a solo dev in Jeju: what I shipped, what broke, " \
            "the security holes I keep finding, the real numbers. No fluff. No 47-agent diagrams."

  ALLOWED_SOURCES = %w[
    newsletter_page sidebar snapdeck_card
  ].freeze
  DEFAULT_SOURCE = "newsletter_page".freeze

  def show
    @subscriber = Subscriber.new
    @name = NAME
    @promise = PROMISE
    @source = sanitized_source
  end

  def subscribe
    @subscriber = Subscriber.new(email: params[:email], source: sanitized_source)

    if @subscriber.save
      SyncSubscriberToBeehiivJob.perform_later(@subscriber.id)
      respond_to do |format|
        format.html { redirect_to newsletter_subdomain_url, notice: "You're in. Check your inbox." }
        format.turbo_stream { flash.now[:notice] = "You're in. Check your inbox." }
      end
    else
      @name = NewsletterController::NAME
      @promise = NewsletterController::PROMISE
      @source = sanitized_source
      respond_to do |format|
        format.html { render :show, status: :unprocessable_content }
        format.turbo_stream { render :show, status: :unprocessable_content }
      end
    end
  end

  private

  def sanitized_source
    candidate = params[:source].to_s
    ALLOWED_SOURCES.include?(candidate) ? candidate : DEFAULT_SOURCE
  end
end
