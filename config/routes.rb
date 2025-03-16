Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  resources :metrics
  # Defines the root path route ("/")
  root 'metrics#index'

  get '/sign_up', to: 'registrations#new'
  post '/sign_up', to: 'registrations#create'

  get '/sign_in', to: 'sessions#new'
  post 'sign_in', to: 'sessions#create'

  delete '/logout', to: 'sessions#destroy'
end
