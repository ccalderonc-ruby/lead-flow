Rails.application.routes.draw do
  # Redirect to localhost from 127.0.0.1 to use same IP address with Vite server
  constraints(host: "127.0.0.1") do
    get "(*path)", to: redirect { |params, req| "#{req.protocol}localhost:#{req.port}/#{params[:path]}" }
  end

  resource :session, only: %i[new create destroy]
  get "login", to: "sessions#new", as: :login
  delete "logout", to: "sessions#destroy", as: :logout

  resource :password_reset, only: %i[new create edit update]
  get "forgot-password", to: "password_resets#new", as: :forgot_password

  root "dashboard#index"

  resources :leads, only: %i[index show new create edit update] do
    collection do
      get :export
    end
  end
  resources :tasks, only: %i[index create update]
  resources :notes, only: %i[index create update destroy]
  resources :meetings, only: %i[index create update]
  resources :opportunities, only: %i[index create update]
  resources :assistants, only: %i[index create destroy]

  namespace :admin do
    resources :users, only: %i[index new create edit update]
    resources :roles, only: :index
    resources :subscriptions, only: %i[index create] do
      collection do
        patch :access, action: :update
        post :grant_all
        post :cancel
        post :resume
      end
    end
  end

  # Legacy advisor settings URL — subscription is admin-managed.
  get "settings/subscription", to: redirect("/admin/subscriptions")
  post "settings/subscription", to: "admin/subscriptions#create"

  post "webhooks/stripe", to: "webhooks/stripe#create"

  get "up" => "rails/health#show", as: :rails_health_check
end
