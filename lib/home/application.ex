defmodule Home.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the page cache to reduce filesystem hits
      {Home.PageCache, %{}},
      {Home.ImageCache, %{}},
      # Start the Telemetry supervisor
      HomeWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Home.PubSub},
      # Start the Endpoint (http/https)
      HomeWeb.Endpoint
      # Start a worker by calling: Home.Worker.start_link(arg)
      # {Home.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Home.Supervisor]
    out = Supervisor.start_link(children, opts)

    # Warm up the page cache
    case {out, Application.get_env(:home, :fill_cache)} do
      {{:ok, _}, true} -> HomeWeb.fill_cache()
      _ -> nil
    end

    out
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    HomeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
