require 'sidekiq/web'

Rails.application.routes.draw do
  resources :metrics do
    get 'search', on: :collection
  end

  root 'metrics#index'

  devise_for :users,
             controllers: {
               omniauth_callbacks: 'users/omniauth_callbacks'
             },
             path: '',
             path_names: {
               sign_in: 'sign_in',
               sign_out: 'logout',
               sign_up: 'sign_up',
               registration: 'users',
               password: 'reset_password'
             }

  namespace :api do
    namespace :v1 do
      get 'strava_authenticate', to: 'authentication#start'
      get 'auth/strava/callback', to: 'authentication#callback'
    end
  end

  mount Sidekiq::Web => '/sidekiq'
end
