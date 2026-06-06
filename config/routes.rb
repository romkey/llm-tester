Rails.application.routes.draw do
  require "sidekiq/web"

  mount Sidekiq::Web => "/sidekiq"

  get "up" => "rails/health#show", as: :rails_health_check

  root "servers#index"

  resources :servers, only: [] do
    post :sync_models, on: :member
  end

  resources :llm_models, only: %i[show], path: "models"

  resources :test_runs, only: %i[index show], path: "tests"
  resources :benchmarks, only: %i[index show] do
    post :run_now, on: :collection
  end

  namespace :settings do
    root to: "home#index"
    resources :servers do
      post :sync_models, on: :member
    end
    resources :llm_models, path: "models"
    resources :test_definitions, path: "tests" do
      post :run_now, on: :member
    end
  end
end
