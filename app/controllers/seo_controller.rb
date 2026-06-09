class SeoController < ApplicationController
  allow_unauthenticated_access

  # Crawler-facing files change over time (new services, updated copy), so they
  # must NOT inherit the 1-year immutable cache that fingerprinted assets get.
  before_action { expires_in 1.hour, public: true }

  def robots
    render layout: false, content_type: "text/plain"
  end

  def sitemap
    render layout: false, content_type: "application/xml"
  end

  def llms
    render layout: false, content_type: "text/plain"
  end
end
