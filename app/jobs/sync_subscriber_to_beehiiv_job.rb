class SyncSubscriberToBeehiivJob < ApplicationJob
  queue_as :default

  retry_on BeehiivClient::Error, wait: :polynomially_longer, attempts: 5

  def perform(subscriber_id)
    subscriber = Subscriber.find(subscriber_id)
    return if subscriber.status == "synced"
    return unless BeehiivClient.configured?

    BeehiivClient.subscribe(email: subscriber.email, source: subscriber.source)
    subscriber.mark_synced!
  rescue BeehiivClient::NotConfigured
    Rails.logger.warn "[Beehiiv] Skipping sync — credentials missing"
  rescue BeehiivClient::Error => e
    Rails.logger.error "[Beehiiv] #{e.message}"
    subscriber.mark_failed!
    raise
  end
end
