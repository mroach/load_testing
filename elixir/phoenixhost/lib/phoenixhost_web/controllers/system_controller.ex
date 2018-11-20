defmodule PhoenixhostWeb.SystemController do
  use PhoenixhostWeb, :controller

  def warmup(conn, _params) do
    json conn, %{status: :running}
  end
end
