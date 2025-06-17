Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  resources :metrics
  # Defines the root path route ("/")
  root 'metrics#index'

  get '/sign_up', to: 'registrations#new'
  post '/sign_up', to: 'registrations#create'
  get 'users/:id/edit', to: 'registrations#edit', as: 'edit_user'
  patch 'users/:id', to: 'registrations#update', as: 'update_user'

  get '/sign_in', to: 'sessions#new'
  post 'sign_in', to: 'sessions#create'

  get '/reset_password', to: 'password_resets#new'
  post '/reset_password', to: 'password_resets#create'
  get '/reset_password/edit', to: 'password_resets#edit'
  patch '/reset_password/edit', to: 'password_resets#update'

  get 'api/v1/strava_authenticate', to: 'api/v1/authentication#authenticate', as: 'strava_authenticate'
  get '/auth/strava/callback', to: 'api/v1/authentication#callback'
  get '/auth/failure', to: 'api/v1/authentication#failure'

  delete '/logout', to: 'sessions#destroy'
end
