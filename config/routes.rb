Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  resource :session, only: %i[ new create destroy ]
  resource :locale, only: :update
  resource :profile, only: %i[ edit update ]

  resources :clients do
    resources :notes, only: :create
  end
  resource :vin_decode, only: :show
  resources :vehicles do
    resources :notes, only: :create
  end
  resources :work_orders do
    member do
      get :print
      patch :status
    end
    resources :work_order_labors, only: %i[ create update destroy ]
    resources :work_order_parts, only: %i[ create update destroy ]
    resources :payments, only: %i[ create destroy ]
    resources :notes, only: :create
  end
  resources :appointments do
    member do
      patch :status
      post :check_in
    end
  end
  resources :notes, only: %i[ edit update destroy ]
  resources :services, except: :show
  resources :parts, except: :show do
    patch :receive, on: :member
  end

  namespace :admin do
    resources :users, except: :show
    resources :employees, except: :show
    resources :bays, except: :show
  end

  root "dashboard#show"
end
