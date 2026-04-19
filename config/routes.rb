Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :customers, only: %i[index show create update destroy]

      resources :vehicles, only: %i[index show create update] do
        member do
          patch :update_mileage
        end
      end

      resources :inventory_items, only: %i[index show create update destroy] do
        member do
          patch :add_quantity
          patch :decrease_quantity
        end
      end

      resources :services, only: %i[index show create update destroy]

      resources :work_orders, only: %i[show create] do
        member do
          patch :assign
          patch :diagnose
          post :line_items, action: :add_line_item
        end
      end
    end
  end
end
