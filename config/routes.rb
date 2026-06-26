Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  resources :users, only: [ :create ]
  get "sign_up", to: "users#new", as: :new_users

  resource :session, only: [ :create, :destroy ]
  get "sign_in", to: "sessions#new", as: :new_session

  resources :bank_accounts, only: [ :new, :create, :show, :edit, :update, :destroy ] do
    resources :imports, only: [ :new, :create ]
    resource :profit_and_loss, only: [ :show ], controller: :profit_and_loss
  end

  resources :imports, only: [ :show ] do
    member do
      get :review
      post :confirm
    end
  end

  resources :transactions, only: [ :update ]

  root "dashboard#index"
end
