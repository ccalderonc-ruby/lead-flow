Rails.application.routes.draw do
  # Redirect to localhost from 127.0.0.1 to use same IP address with Vite server
  constraints(host: "127.0.0.1") do
    get "(*path)", to: redirect { |params, req| "#{req.protocol}localhost:#{req.port}/#{params[:path]}" }
  end

  resource :session, only: %i[new create destroy]
  get "login", to: "sessions#new", as: :login
  delete "logout", to: "sessions#destroy", as: :logout

  root "dashboard#index"

  resources :leads, only: %i[index show new create edit update]
  resources :tasks, only: %i[index create update]
  resources :notes, only: :create
  resources :meetings, only: %i[index create]
  resources :opportunities, only: %i[index update]

  namespace :admin do
    resources :users, only: %i[index new create edit update]
    resources :roles, only: :index
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
