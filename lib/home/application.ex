defmodule Home.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
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
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    HomeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
