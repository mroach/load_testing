Rails.application.routes.draw do
  post "/login", to: "benchmark#login"
  get "/warmup", to: "benchmark#warmup"
  get "/alive", to: "benchmark#alive"
  get "/platform", to: "benchmark#platform"
end
