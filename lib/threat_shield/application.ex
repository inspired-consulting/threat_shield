defmodule ThreatShield.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Task.Supervisor, name: ThreatShield.TaskSupervisor},
      # Start the Telemetry supervisor
      ThreatShieldWeb.Telemetry,
      # Start the Ecto repository
      ThreatShield.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: ThreatShield.PubSub},
      # Start Finch
      {Finch, name: ThreatShield.Finch},
      # Start the Endpoint (http/https)
      ThreatShieldWeb.Endpoint,
      # Start a worker by calling: ThreatShield.Worker.start_link(arg)
      ThreatShield.Periodically,
      ThreatShield.DynamicAttribute
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ThreatShield.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ThreatShieldWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
