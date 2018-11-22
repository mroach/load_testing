defmodule PhoenixhostWeb.BenchmarkController do
  use PhoenixhostWeb, :controller

  def warmup(conn, _params) do
    text conn, "OK"
  end

  def alive(conn, _params) do
    text conn, "OK"
  end

  def platform(conn, _params) do
    {:ok, version} = :application.get_key(:phoenix, :vsn)
    text conn, "Phoenix #{version}/Elixir #{System.version}/OTP #{System.otp_release} (#{Mix.env})"
  end

  def login(conn, %{"user" => user, "pass" => pass}) do
    response = %{
      user: user,
      token: Base.url_encode64(pass)
    }
    json conn, response
  end
  def login(conn, _), do: json(conn, %{error: "bad"})
end
