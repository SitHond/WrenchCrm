Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resource :session, only: %i[ new create destroy ]
  resource :locale, only: :update
  resource :profile, only: %i[ edit update ]

  resources :people do
    resources :notes, only: :create
  end
  resources :families do
    resources :notes, only: :create
  end
  resources :notes, only: %i[ edit update destroy ]
  resources :groups do
    resources :group_memberships, only: %i[ create update destroy ]
    resources :group_roles, only: %i[ create update destroy ]
  end

  namespace :admin do
    resources :users, except: :show
  end

  root "dashboard#show"
end
