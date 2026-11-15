Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  root "categories#index"

  # Súgó
  get "/help", to: "help#show", as: :help

  # Autentikáció
  get "/login", to: "sessions#new"
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy"

  get "/register", to: "registrations#new"
  post "/register", to: "registrations#create"

  get "/email_confirmation", to: "email_confirmations#show"

  get "/password_reset/new", to: "password_resets#new", as: :new_password_reset
  post "/password_reset", to: "password_resets#create", as: :password_reset
  get "/password_reset/edit", to: "password_resets#edit", as: :edit_password_reset
  patch "/password_reset", to: "password_resets#update"

  # Saját profil
  get "/profile", to: "profiles#show", as: :profile
  patch "/profile", to: "profiles#update"
  patch "/profile/password", to: "profiles#update_password", as: :profile_password

  # Versenyszámok, rekordok és mellékletek
  resources :categories, only: [ :index, :show, :new, :create, :edit, :update ]
  resources :records, only: [ :new, :create, :edit, :update, :destroy ]
  resources :attachments, only: [ :show ]

  # Adminisztráció
  namespace :admin do
    root to: "records#index"
    resources :categories, only: [ :index, :create, :edit, :update, :destroy ]
    resources :users, only: [ :index, :update, :destroy ] do
      post :reset_password, on: :member
    end
    resources :invite_codes, only: [ :index, :create, :update, :destroy ]
    resources :seasons, only: [ :index, :create, :edit, :update, :destroy ]
    resources :settings, only: [ :index, :update ]
    resources :records, only: [ :index, :update, :destroy ]
  end
end
