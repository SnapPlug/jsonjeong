class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :newsletter_subdomain_url, :apex_root_url

  private

  def newsletter_subdomain_url
    "#{scheme_for_links}://newsletter.#{apex_host_with_port}/"
  end

  def apex_root_url
    "#{scheme_for_links}://#{apex_host_with_port}/"
  end

  def scheme_for_links
    request.ssl? ? "https" : "http"
  end

  def apex_host_with_port
    request.host_with_port.sub(/\A(?:newsletter|www)\./, "")
  end
end
