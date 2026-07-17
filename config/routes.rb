Rails.application.routes.draw do
  resource :registration, only: %i[new create]
  resource :session
  resources :passwords, param: :token
  resources :homes, only: %i[index new create show] do
    resources :items, only: %i[index new create show edit update]
    resources :entries, only: %i[new create show]
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "registrations#new"
end
