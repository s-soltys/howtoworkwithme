Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  # Admin routes
  get "admin/component-library", to: "admin#component_library"

  # User Story 2: Employer creates organization and configures questionnaire
  root "organizations#new"

  resources :organizations, param: :unique_token, only: [ :create, :show ] do
    resources :questionnaires, only: [ :new, :create ], shallow: true
  end

  # User Story 1: Employee completes questionnaire and generates profile
  resources :questionnaires, param: :unique_token, only: [ :show, :edit ] do
    member do
      post :start
      post :generate_link
      get :responses, to: "questionnaires#responses"
    end

    resources :categories, only: [ :create ]
  end

  resources :categories, only: [ :update, :destroy ] do
    resources :questions, only: [ :create ]
  end

  resources :questions, only: [ :update, :destroy ]

  resources :responses, param: :unique_token, only: [ :edit, :update ] do
    member do
      post :submit
    end
  end

  resources :profiles, param: :unique_token, only: [ :show ]
end
