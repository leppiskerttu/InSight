Rails.application.routes.draw do
  get "/s/:token", to: "public_surveys#show", as: :public_survey
  post "/s/:token/responses", to: "public_surveys#create_response", as: :public_survey_responses

  resource :session
  resources :passwords, param: :token
  root "dashboard#index"
  resources :surveys do
    resources :questions, except: :index

    member do
      patch :publish
      patch :close
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
