Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "/metrics/new", to: "metrics#new", as: :new_metric
  post "/metrics", to: "metrics#create", as: :metrics
  get "/metrics/:id", to: "metrics#show", as: :metric_path
  get "/metrics/:id/edit", to: "metrics#edit", as: :edit_metric_path
  patch "/metrics/:id", to: "metrics#update"
  delete "metrics/:id", to: "metrics#destroy"
  # Defines the root path route ("/")
  root "metrics#index"
end
