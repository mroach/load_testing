Rails.application.routes.draw do
  post "/login", to: "authentication#login"
  get "/warmup", to: "system#warmup"
end
