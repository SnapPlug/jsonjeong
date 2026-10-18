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

  # 내부 운영 도구 — 계약현황·헬스체크 관제 (옛 Overload). 로그인 필수.
  constraints subdomain: "ops" do
    scope module: :ops, as: :ops do
      root "dashboard#index"
      resources :clients, only: %i[show update]
      resources :contracts, only: %i[index new create update]
      resources :payments, only: :update
      resource :health_check, only: :create
    end
  end

  constraints subdomain: /\A(www)?\z/ do
    # Crawler files served dynamically (short cache, not the 1-year asset cache)
    get "/robots.txt" => "seo#robots", defaults: { format: "text" }
    get "/sitemap.xml" => "seo#sitemap", defaults: { format: "xml" }
    get "/llms.txt" => "seo#llms", defaults: { format: "text" }

    # 뉴스레터는 snapplug.app으로 모았다 — 예전 /newsletter 주소도 그리로
    get "newsletter", to: redirect(SNAPPLUG_NEWSLETTER_URL), as: :newsletter

    # Apex POST handler — sidebar form on dashboard submits here
    post "newsletter", to: "newsletter#subscribe", as: :newsletter_subscribe

    # 아이디어 아카이브 — 한국어는 /, 영어는 /en
    scope "(:locale)", locale: /en/ do
      root "ideas#index"
      resources :ideas, only: :show, param: :slug
    end
  end
end
