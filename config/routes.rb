Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "privacy" => "privacy#show", as: :privacy_policy

  resource :session, only: %i[ new create destroy ] do
    get :two_factor
    post :verify
  end
  resource :two_factor, only: %i[ new create destroy ], controller: "two_factor"
  resource :locale, only: :update
  resource :profile, only: %i[ edit update ]

  resources :clients do
    resources :notes, only: :create
    resource :anonymization, only: :create
    resources :consents, only: :create do
      collection { get :print }
      member { patch :withdraw }
    end
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
  resources :leads do
    get :board, on: :collection
    patch :move, on: :member
    resources :notes, only: :create
  end
  resources :service_reminders, only: %i[ index create update destroy ] do
    member do
      patch :contacted
      patch :snooze
    end
  end
  resources :tasks, only: %i[ index create edit update destroy ] do
    patch :toggle, on: :member
  end
  resources :services, except: :show do
    get :price_list, on: :collection
  end
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
      get :funnel
    end
  end

  resource :shop_settings, only: %i[ edit update ]
  post "anonymizations/inactive" => "anonymizations#inactive", as: :anonymize_inactive
  resources :complexity_levels, only: %i[ create destroy ]
  resources :ad_sources, only: %i[ create update ]
  resources :loyalty_tiers, only: %i[ create destroy ]
  resources :markup_rules, only: %i[ create destroy ]
  resources :catalog_categories, only: %i[ create destroy ]

  resources :data_imports, path: "imports", only: %i[ index create show update ] do
    member { get :errors }
    collection do
      get "template/:kind", action: :template, as: :template
      post :splus
    end
  end
  get "exports/full" => "exports#full", as: :full_export
  resources :audit_events, only: :index

  namespace :admin do
    resources :users, except: :show do
      delete :two_factor, on: :member, action: :reset_two_factor
    end
    resources :employees, except: :show
    resources :bays, except: :show
  end

  root "dashboard#show"
end
