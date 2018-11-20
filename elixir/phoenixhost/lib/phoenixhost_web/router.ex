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
    plug :accepts, ["json"]
  end

  scope "/", PhoenixhostWeb do
    pipe_through :api
    post "/login", AuthenticationController, :login
    get "/warmup", SystemController, :warmup
  end

  # Other scopes may use custom stacks.
  # scope "/api", PhoenixhostWeb do
  #   pipe_through :api
  # end
end
