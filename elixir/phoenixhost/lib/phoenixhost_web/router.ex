defmodule PhoenixhostWeb.Router do
  use PhoenixhostWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json", "text"]
  end

  scope "/", PhoenixhostWeb do
    pipe_through :api

    get "/warmup", BenchmarkController, :warmup
    get "/alive", BenchmarkController, :alive
    get "/platform", BenchmarkController, :platform
    post "/login", BenchmarkController, :login
  end

  # Other scopes may use custom stacks.
  # scope "/api", PhoenixhostWeb do
  #   pipe_through :api
  # end
end
