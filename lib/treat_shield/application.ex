defmodule TreatShield.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      TreatShieldWeb.Telemetry,
      # Start the Ecto repository
      TreatShield.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: TreatShield.PubSub},
      # Start Finch
      {Finch, name: TreatShield.Finch},
      # Start the Endpoint (http/https)
      TreatShieldWeb.Endpoint
      # Start a worker by calling: TreatShield.Worker.start_link(arg)
      # {TreatShield.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TreatShield.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    TreatShieldWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
