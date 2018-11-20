defmodule PhoenixhostWeb.AuthenticationController do
  use PhoenixhostWeb, :controller

  def login(conn, %{"user" => user, "pass" => pass}) do
    response = %{
      user: user,
      token: Base.url_encode64(pass)
    }
    json conn, response
  end
  def login(conn, _), do: json(conn, %{error: "bad"})
end
