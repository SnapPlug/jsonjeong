Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Newsletter subdomain — newsletter.jsonjeong.com (or newsletter.lvh.me in dev)
  constraints subdomain: "newsletter" do
    root "newsletter#show", as: :newsletter_root
    post "/" => "newsletter#subscribe", as: :newsletter_subscribe_on_subdomain
  end

  # Apex (no subdomain or www) — dashboard
  constraints subdomain: /\A(www)?\z/ do
    root "dashboard#index"

    # Back-compat: /newsletter on apex 301s to newsletter subdomain
    get "newsletter", to: redirect { |_, req|
      base = req.host_with_port.sub(/\A(?:newsletter|www)\./, "")
      scheme = req.ssl? ? "https" : "http"
      "#{scheme}://newsletter.#{base}/"
    }, as: :newsletter

    # Apex POST handler — sidebar form on dashboard submits here
    post "newsletter", to: "newsletter#subscribe", as: :newsletter_subscribe
  end
end
