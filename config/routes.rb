Rails.application.routes.draw do
  resource :registration, only: %i[new create]
  resource :session
  resources :passwords, param: :token
  resources :homes, only: %i[index show]

  get "up" => "rails/health#show", as: :rails_health_check

  root "registrations#new"
end
