require "net/http"
require "uri"
require "json"

class BeehiivClient
  Error = Class.new(StandardError)
  NotConfigured = Class.new(Error)

  ENDPOINT = "https://api.beehiiv.com/v2".freeze

  def self.configured?
    api_key.present? && publication_id.present?
  end

  # Reads from Rails credentials first (recommended for production via Kamal),
  # falls back to ENV for ad-hoc local overrides.
  #   bin/rails credentials:edit
  #     beehiiv:
  #       api_key: bh_...
  #       publication_id: pub_...
  def self.api_key
    Rails.application.credentials.dig(:beehiiv, :api_key) || ENV["BEEHIIV_API_KEY"]
  end

  def self.publication_id
    Rails.application.credentials.dig(:beehiiv, :publication_id) || ENV["BEEHIIV_PUBLICATION_ID"]
  end

  def self.subscribe(email:, source: "jsonjeong.com")
    raise NotConfigured, "BEEHIIV_API_KEY or BEEHIIV_PUBLICATION_ID not set" unless configured?

    uri = URI("#{ENDPOINT}/publications/#{publication_id}/subscriptions")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{api_key}"
    request["Content-Type"] = "application/json"
    request.body = {
      email: email,
      reactivate_existing: true,
      send_welcome_email: true,
      utm_source: source
    }.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: 8) do |http|
      http.request(request)
    end

    unless response.is_a?(Net::HTTPSuccess)
      raise Error, "Beehiiv API #{response.code}: #{response.body.to_s.truncate(200)}"
    end

    JSON.parse(response.body)
  end
end
