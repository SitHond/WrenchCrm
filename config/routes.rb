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
  get "calendar" => "calendar#show", as: :calendar
  resources :work_orders do
    get :board, on: :collection
    member do
      get :print
      patch :status
    end
    resources :work_order_labors, only: %i[ create update destroy ] do
      resources :performers, controller: "work_order_labor_performers", only: %i[ create destroy ]
    end
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
  resources :service_reminders, only: %i[ index create update destroy ] do
    member do
      patch :contacted
      patch :snooze
    end
  end
  resources :tasks, only: %i[ index create edit update destroy ] do
    patch :toggle, on: :member
  end
  resources :services, except: :show
  resources :parts do
    member do
      patch :receive
      patch :write_off
      patch :count
      post :add_analog
      delete :remove_analog
    end
  end
  resources :suppliers
  resources :purchase_receipts do
    post :post, on: :member
    post :from_reorder, on: :collection
    resources :purchase_receipt_lines, only: %i[ create update destroy ]
  end
  resources :sales, only: %i[ index show new create destroy ]
  resources :cash_operations, only: %i[ index new create destroy ] do
    post :transfer, on: :collection
  end
  resources :cash_accounts, only: %i[ index new create edit update ]
  resources :expense_categories, only: %i[ create update ]
  resources :payroll, only: %i[ index show ]
  resources :salary_payouts, only: %i[ create destroy ]
  resources :payroll_adjustments, only: %i[ create destroy ]
  resources :reports, only: :index do
    collection do
      get :labor
      get :parts
      get :stock
      get :sources
      get :reorder
    end
  end

  resource :shop_settings, only: %i[ edit update ]
  resources :complexity_levels, only: %i[ create destroy ]
  resources :ad_sources, only: %i[ create update ]
  resources :loyalty_tiers, only: %i[ create destroy ]
  resources :markup_rules, only: %i[ create destroy ]
  resources :catalog_categories, only: %i[ create destroy ]

  namespace :admin do
    resources :users, except: :show
    resources :employees, except: :show
    resources :bays, except: :show
  end

  root "dashboard#show"
end
