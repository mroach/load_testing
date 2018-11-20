defmodule Phoenixhost.Repo do
  use Ecto.Repo,
    otp_app: :phoenixhost,
    adapter: Ecto.Adapters.Postgres
end
